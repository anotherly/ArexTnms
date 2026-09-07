(() => {
  const defaultStationName = "김포공항";
  const stations = [
    {name:"서울", col:0, row:0, status:"normal"},
    {name:"공덕역", col:1, row:1, status:"normal"},
    {name:"홍대입구", col:2, row:0, status:"normal"},
    {name:"DMC", col:3, row:1, status:"normal"},
    {name:"마곡나루", col:4, row:0, status:"normal"},
    {name:"김포공항", col:5, row:1, status:"danger", red:1, orange:1},
    {name:"계양", col:6, row:0, status:"warning", orange:1},
    {name:"검암", col:7, row:1, status:"normal"},
    {name:"청라", col:8, row:0, status:"normal"},
    {name:"영종", col:9, row:1, status:"normal"},
    {name:"운서", col:10, row:2, status:"normal"},
    {name:"공항화물청사", col:0, row:4, status:"normal"},
    {name:"T1", col:1, row:3, status:"normal"},
    {name:"T2", col:2, row:4, status:"normal"},
    {name:"차량기지", col:3, row:3, status:"system"},
    {name:"기지SSP", col:4, row:4, status:"system"},
    {name:"운서SSP", col:5, row:3, status:"system"},
    {name:"SIG2", col:6, row:4, status:"system"},
    {name:"청라SSP", col:7, row:3, status:"system"},
    {name:"본사", col:8, row:4, status:"system"},
    {name:"계양SS", col:9, row:3, status:"system"}
  ];

  const columnPositions = [5.88235294,14.70588235,23.52941176,32.35294118,41.17647059,50,58.82352941,67.64705882,76.47058824,85.29411765,94.11764706];
  const rowPositions = [16.66666667,33.33333333,50,66.66666667,83.33333333];
  const nodes = document.querySelector("#stationNodes");
  const network = document.querySelector("#stationNetwork");
  const tabs = [...document.querySelectorAll(".system-tabs button")];
  let currentSystem = "SCADA 출입보안설비";
  let selectedStation = defaultStationName;

  const svgNamespace = "http://www.w3.org/2000/svg";
  const hexHalfWidth = 100;
  const hexHalfHeight = 86.60254038;
  const networkViewWidth = 1700;
  const networkViewHeight = hexHalfHeight * 6;
  const shapeLayer = document.createElementNS(svgNamespace, "svg");
  shapeLayer.setAttribute("class", "station-network-shapes");
  shapeLayer.setAttribute("viewBox", `0 0 ${networkViewWidth} ${networkViewHeight}`);
  shapeLayer.setAttribute("preserveAspectRatio", "none");
  shapeLayer.setAttribute("aria-hidden", "true");
  nodes.appendChild(shapeLayer);

  const shapeStyles = {
    normal:{fill:"#f2fbf6",stroke:"#0dad63",priority:1},
    system:{fill:"#f2f7ff",stroke:"#1877e8",priority:2},
    warning:{fill:"#fff8ec",stroke:"#f59a00",priority:3},
    offline:{fill:"#f4f6f9",stroke:"#8290a6",priority:4},
    danger:{fill:"#fff3f3",stroke:"#f13838",priority:5}
  };
  const selectedStyle = {fill:"#176df4",stroke:"#0b4fba",priority:10};

  function countsMarkup(station){
    const result = [];
    if(station.red) result.push(`<span><i style="background:#f13838"></i>${station.red}건</span>`);
    if(station.orange) result.push(`<span><i style="background:#f59a00"></i>${station.orange}건</span>`);
    if(station.gray) result.push(`<span><i style="background:#8290a6"></i>${station.gray}건</span>`);
    return result.join("");
  }

  function createNode(station){
    const button = document.createElement("button");
    button.type = "button";
    button.className = `station-node status-${station.status}`;
    button.dataset.station = station.name;
    button.style.setProperty("--x", `${columnPositions[station.col]}%`);
    button.style.setProperty("--y", `${rowPositions[station.row]}%`);
    button.setAttribute("aria-label", `${station.name} 선택`);
    button.setAttribute("aria-pressed", "false");
    button.innerHTML = `<span class="station-node-content"><span class="station-name">${station.name}</span><span class="station-counts">${countsMarkup(station)}</span></span>`;
    button.addEventListener("click", () => selectStation(station, button));
    return button;
  }

  stations.forEach(station => nodes.appendChild(createNode(station)));

  function hexPoints(station){
    const centerX = hexHalfWidth + (station.col * hexHalfWidth * 1.5);
    const centerY = hexHalfHeight + (station.row * hexHalfHeight);
    return [
      [centerX - (hexHalfWidth / 2),centerY - hexHalfHeight],
      [centerX + (hexHalfWidth / 2),centerY - hexHalfHeight],
      [centerX + hexHalfWidth,centerY],
      [centerX + (hexHalfWidth / 2),centerY + hexHalfHeight],
      [centerX - (hexHalfWidth / 2),centerY + hexHalfHeight],
      [centerX - hexHalfWidth,centerY]
    ];
  }

  function edgeKey(start,end){
    const first = `${start[0].toFixed(4)},${start[1].toFixed(4)}`;
    const second = `${end[0].toFixed(4)},${end[1].toFixed(4)}`;
    return first < second ? `${first}|${second}` : `${second}|${first}`;
  }

  function renderNetworkShapes(){
    shapeLayer.textContent = "";
    const edges = new Map();

    stations.forEach(station => {
      const points = hexPoints(station);
      const style = station.name === selectedStation ? selectedStyle : (shapeStyles[station.status] || shapeStyles.normal);
      const polygon = document.createElementNS(svgNamespace, "polygon");
      polygon.setAttribute("class", "network-hex-fill");
      polygon.setAttribute("points", points.map(point => point.join(",")).join(" "));
      polygon.setAttribute("fill", style.fill);
      shapeLayer.appendChild(polygon);

      points.forEach((start,index) => {
        const end = points[(index + 1) % points.length];
        const key = edgeKey(start,end);
        const existing = edges.get(key);
        if(!existing || style.priority > existing.style.priority){
          edges.set(key,{start,end,style});
        }
      });
    });

    edges.forEach(edge => {
      const line = document.createElementNS(svgNamespace, "line");
      line.setAttribute("class", "network-edge");
      line.setAttribute("x1", edge.start[0]);
      line.setAttribute("y1", edge.start[1]);
      line.setAttribute("x2", edge.end[0]);
      line.setAttribute("y2", edge.end[1]);
      line.setAttribute("stroke", edge.style.stroke);
      line.setAttribute("stroke-width", 1.5);
      shapeLayer.appendChild(line);
    });
  }

  const networkAspectRatio = 3.27165;

  function fitStationNetwork(){
    const availableWidth = Math.max(0, network.clientWidth - 24);
    const availableHeight = Math.max(0, network.clientHeight - 20);
    if(!availableWidth || !availableHeight) return;

    const fittedWidth = Math.min(1175, availableWidth, availableHeight * networkAspectRatio);
    nodes.style.width = `${Math.floor(fittedWidth)}px`;
  }

  if(typeof ResizeObserver === "function"){
    new ResizeObserver(fitStationNetwork).observe(network);
  }else{
    window.addEventListener("resize", fitStationNetwork);
  }
  window.requestAnimationFrame(fitStationNetwork);

  function statusClass(station){
    if(station.status === "warning") return "orange";
    if(station.status === "danger") return "red";
    if(station.status === "offline") return "gray";
    return "green";
  }

  function updateDetails(station){
    const stationLabel = station.name.endsWith("역") || /^(T1|T2|DMC|SIG2)$/.test(station.name) ? station.name : `${station.name}역`;
    document.querySelector("#detailStation").textContent = stationLabel;
    document.querySelector("#detailMeta").textContent = `선택 시스템　${currentSystem}　·　EMS ID : 16`;
    document.querySelector("#configTitle").textContent = `${currentSystem} 구성정보`;
    document.querySelector("#deviceName").textContent = currentSystem === "영상감시설비" ? "영상감시 장비" : `${currentSystem.replace("설비","")} 장비`;
    document.querySelector("#stationName").textContent = station.name;
    document.querySelector("#deviceType").textContent = currentSystem === "영상감시설비" ? "카메라 · NVR · VMS" : "연동 수신값 표시";
    document.querySelector("#eventDot1").className = `dot ${statusClass(station)}`;

    if(station.status === "danger"){
      document.querySelector("#eventPrimary").textContent = `${station.name} 컨트롤러 통신 장애`;
      document.querySelector("#eventSecondary").textContent = "장애 이벤트 수신 중";
      document.querySelector("#history1").textContent = `${currentSystem} 장애 이력`;
      document.querySelector("#history2").textContent = "EVENT-HISTORY 장애 수신값";
      document.querySelector("#history3").textContent = "EVENT-ACTION 조치 대기";
    }else if(station.status === "warning"){
      document.querySelector("#eventPrimary").textContent = `${station.name} 주의 이벤트`;
      document.querySelector("#eventSecondary").textContent = "임계치 확인 필요";
      document.querySelector("#history1").textContent = `${currentSystem} 주의 이력`;
      document.querySelector("#history2").textContent = "EVENT-HISTORY 주의 수신값";
      document.querySelector("#history3").textContent = "상태 확인 중";
    }else{
      document.querySelector("#eventPrimary").textContent = `${station.name} 주요 장애 없음`;
      document.querySelector("#eventSecondary").textContent = "최근 수집 상태 정상";
      document.querySelector("#history1").textContent = `${currentSystem} 최근 장애 없음`;
      document.querySelector("#history2").textContent = "EVENT-HISTORY 정상";
      document.querySelector("#history3").textContent = "EVENT-ACTION 정상";
    }
  }

  function selectStation(station, button){
    document.querySelectorAll(".station-node").forEach(node => {
      node.classList.remove("is-selected");
      node.setAttribute("aria-pressed","false");
    });
    button.classList.add("is-selected");
    button.setAttribute("aria-pressed","true");
    selectedStation = station.name;
    renderNetworkShapes();
    updateDetails(station);
  }

  tabs.forEach(tab => tab.addEventListener("click", () => {
    tabs.forEach(item => {
      item.classList.toggle("active", item === tab);
      item.setAttribute("aria-selected", item === tab ? "true" : "false");
    });
    currentSystem = tab.dataset.system;
    const station = stations.find(item => item.name === selectedStation) || stations[5];
    updateDetails(station);
  }));

  function selectDefaultStation(){
    const station = stations.find(item => item.name === defaultStationName) || stations[0];
    const button = [...document.querySelectorAll(".station-node")].find(item => item.dataset.station === station.name);
    if(station && button) selectStation(station, button);
  }

  document.querySelector("#clearStation").addEventListener("click", selectDefaultStation);

  const modal = document.querySelector("#detailModal");
  document.querySelector("#detailButton").addEventListener("click", () => {
    document.querySelector("#modalTitle").textContent = `${selectedStation} · ${currentSystem} 상세`;
    document.querySelector("#modalBody").textContent = "선택한 역사와 시스템의 상세 화면으로 연결되는 영역입니다.";
    if(typeof modal.showModal === "function") modal.showModal();
  });
  document.querySelector("#modalClose").addEventListener("click", () => modal.close());
  document.querySelector("#modalOk").addEventListener("click", () => modal.close());

  selectDefaultStation();

})();
