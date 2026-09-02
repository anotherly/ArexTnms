
(() => {
  const stations = [
    {name:"서울역", status:"normal"},
    {name:"공덕", status:"normal"},
    {name:"홍대입구", status:"normal"},
    {name:"DMC", status:"normal"},
    {name:"마곡나루", status:"normal"},
    {name:"김포공항", status:"danger", red:1, orange:1},
    {name:"계양", status:"warning", orange:1},
    {name:"검암", status:"normal"},
    {name:"청라", status:"normal"},
    {name:"영종", status:"danger", red:1},
    {name:"운서", status:"warning", orange:1},

    {name:"공항화물청사", status:"normal"},
    {name:"T1", status:"normal"},
    {name:"T2", status:"normal"},
    {name:"장기", status:"normal"},
    {name:"운양", status:"normal"},
    {name:"구래", status:"warning", orange:1},
    {name:"양촌", status:"normal"},
    {name:"마산", status:"warning", orange:1},
    {name:"가정", status:"normal"},
    {name:"서부구기지", status:"offline", gray:1}
  ];

  const statusMeta = {
    normal: {label:"정상", color:"#11a757"},
    warning:{label:"주의", color:"#f59a00"},
    danger: {label:"장애", color:"#f13838"},
    offline:{label:"통신 단절", color:"#8290a6"}
  };

  const rowTop = document.querySelector("#stationRowTop");
  const rowBottom = document.querySelector("#stationRowBottom");
  const detailGrid = document.querySelector("#detailGrid");
  const stationName = document.querySelector("#stationName");
  const deviceName = document.querySelector("#deviceName");
  const deviceType = document.querySelector("#deviceType");
  const eventDot1 = document.querySelector("#eventDot1");
  const eventPrimary = document.querySelector("#eventPrimary");
  const eventMeta = document.querySelector("#eventMeta");
  const eventSecondary = document.querySelector("#eventSecondary");
  const history1 = document.querySelector("#history1");
  const history2 = document.querySelector("#history2");
  const history3 = document.querySelector("#history3");
  const detailButton = document.querySelector("#detailButton");
  const modal = document.querySelector("#detailModal");
  const modalClose = document.querySelector("#modalClose");
  const modalOk = document.querySelector("#modalOk");
  const modalTitle = document.querySelector("#modalTitle");
  const modalBody = document.querySelector("#modalBody");
  const tabs = [...document.querySelectorAll(".system-tabs button")];

  let currentSystem = "영상감시설비";
  let selectedStation = "김포공항";
  let animationTimer = 0;

  function countsMarkup(station){
    const chunks = [];
    if(station.red) chunks.push(`<span><i style="background:#f13838"></i>${station.red}건</span>`);
    if(station.orange) chunks.push(`<span><i style="background:#f59a00"></i>${station.orange}건</span>`);
    if(station.gray) chunks.push(`<span><i style="background:#8290a6"></i>${station.gray}건</span>`);
    return chunks.join("");
  }

  function stationButton(station){
    const button = document.createElement("button");
    button.type = "button";
    button.className = `station-hex status-${station.status}`;
    button.dataset.station = station.name;
    button.setAttribute("aria-label", `${station.name} 선택`);
    button.innerHTML = `
      <svg viewBox="0 0 101.512 117.067" aria-hidden="true" preserveAspectRatio="none">
        <polygon class="hex-pulse" points="50.756,0 101.512,29.267 101.512,87.800 50.756,117.067 0,87.800 0,29.267"></polygon>
        <polygon class="hex-base" points="50.756,0 101.512,29.267 101.512,87.800 50.756,117.067 0,87.800 0,29.267"></polygon>
        <polygon class="hex-selected" points="50.756,2 99.5,30.2 99.5,86.8 50.756,115.067 2,86.8 2,30.2"></polygon>
      </svg>
      <span class="station-content">
        <span class="station-name">${station.name}</span>
        <span class="station-counts">${countsMarkup(station)}</span>
      </span>
    `;
    button.addEventListener("click", () => selectStation(station, button));
    return button;
  }

  stations.slice(0, 11).forEach(st => rowTop.appendChild(stationButton(st)));
  stations.slice(11).forEach(st => rowBottom.appendChild(stationButton(st)));

  function findButton(name){
    return document.querySelector(`.station-hex[data-station="${CSS.escape(name)}"]`);
  }

  function selectStation(station, button){
    window.clearTimeout(animationTimer);

    document.querySelectorAll(".station-hex").forEach(el => {
      el.classList.remove("is-selected", "is-pressing");
      el.setAttribute("aria-pressed","false");
    });

    button.classList.add("is-pressing");
    void button.offsetWidth;

    window.setTimeout(() => {
      button.classList.add("is-selected");
      button.setAttribute("aria-pressed","true");
    }, 120);

    animationTimer = window.setTimeout(() => {
      button.classList.remove("is-pressing");
    }, 650);

    selectedStation = station.name;
    updateDetails(station);
  }

  function updateDetails(station){
    detailGrid.classList.remove("is-changing");
    void detailGrid.offsetWidth;
    detailGrid.classList.add("is-changing");

    stationName.textContent = `${station.name}역`;
    deviceName.textContent = currentSystem === "영상감시설비" ? "열화상카메라" : `${currentSystem} 전체`;
    deviceType.textContent = currentSystem === "영상감시설비"
      ? "카메라 · NVR · VMS"
      : "선택 시스템 구성 장비";

    eventDot1.className = `dot ${station.status === "danger" ? "red" : station.status === "warning" ? "orange" : station.status === "offline" ? "gray" : "green"}`;

    if(station.name === "김포공항" && currentSystem === "영상감시설비"){
      eventPrimary.textContent = "저장장치에서 장애 발생";
      eventMeta.textContent = "이벤트 발생시간 · 설비/장소 · 경고1";
      eventSecondary.textContent = "이벤트 발생 중";
      history1.textContent = "열화상카메라 장애 (1대)";
      history2.textContent = "EVENT-HISTORY 수신 오류";
      history3.textContent = "EVENT-ACTION 수신 성공";
      return;
    }

    const meta = statusMeta[station.status];
    if(station.status === "normal"){
      eventPrimary.textContent = `${station.name} 주요 장애 없음`;
      eventMeta.textContent = `${currentSystem} · 현재 상태 ${meta.label}`;
      eventSecondary.textContent = "최근 수집 상태 정상";
      history1.textContent = `${station.name} 최근 장애 없음`;
      history2.textContent = "이벤트 수신 정상";
      history3.textContent = "상태 수집 정상";
    }else if(station.status === "warning"){
      eventPrimary.textContent = `${station.name} 주의 이벤트 확인 필요`;
      eventMeta.textContent = `${currentSystem} · 현재 상태 ${meta.label}`;
      eventSecondary.textContent = "주의 이벤트 수신 중";
      history1.textContent = `${station.name} 주의 이벤트 발생`;
      history2.textContent = "EVENT-CURRENT 확인 필요";
      history3.textContent = "상태 수집 정상";
    }else if(station.status === "danger"){
      eventPrimary.textContent = `${station.name} 장애 이벤트 확인 필요`;
      eventMeta.textContent = `${currentSystem} · 현재 상태 ${meta.label}`;
      eventSecondary.textContent = "장애 이벤트 수신 중";
      history1.textContent = `${station.name} 장애 발생`;
      history2.textContent = "EVENT-HISTORY 확인 필요";
      history3.textContent = "조치 이력 확인 필요";
    }else{
      eventPrimary.textContent = `${station.name} 통신 단절 상태`;
      eventMeta.textContent = `${currentSystem} · 현재 상태 ${meta.label}`;
      eventSecondary.textContent = "통신 복구 여부 확인 필요";
      history1.textContent = `${station.name} 통신 단절`;
      history2.textContent = "상태 수집 중단";
      history3.textContent = "현장/네트워크 점검 필요";
    }
  }

  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(el => {
        el.classList.toggle("active", el === tab);
        el.setAttribute("aria-selected", el === tab ? "true" : "false");
      });
      currentSystem = tab.dataset.system;
      const st = stations.find(s => s.name === selectedStation) || stations[5];
      updateDetails(st);
    });
  });

  detailButton.addEventListener("click", () => {
    modalTitle.textContent = `${selectedStation}역 · ${currentSystem} 상세`;
    modalBody.textContent = "선택한 역사와 시스템의 상세 화면으로 연결되는 영역입니다. 실제 개발 시 상세 페이지 또는 팝업 라우팅과 연결하면 됩니다.";
    if(typeof modal.showModal === "function") modal.showModal();
  });
  [modalClose, modalOk].forEach(btn => btn.addEventListener("click", () => modal.close()));

  /*
   * 최초 화면은 제공된 첫 번째 SVG처럼 "선택 전" 상태를 유지합니다.
   * 어느 역사도 선택 테두리를 갖지 않습니다.
   */
  stationName.textContent = "전체역사";
  deviceName.textContent = "영상감시설비 전체";
  deviceType.textContent = "카메라 · NVR · 저장장치";
  eventDot1.className = "dot red";
  eventPrimary.textContent = "김포공항역 저장장치 장애";
  eventMeta.textContent = "이벤트 발생시간 · 설비/장소 · 경고1";
  eventSecondary.textContent = "영종역 경고 발생";
  history1.textContent = "김포공항역 카메라 장애 (1대)";
  history2.textContent = "영종역 저장장치 경고";
  history3.textContent = "계양역 EVENT-HISTORY 수신 오류";
  selectedStation = "";

  const menuToggle = document.querySelector("#menuToggle");
  menuToggle?.addEventListener("click", () => {
    document.body.classList.toggle("menu-collapsed");
  });
})();
document.querySelectorAll('.nav-item').forEach(function(item){
  item.addEventListener('click',function(){
    const keyMap={'대시보드':'dashboard','설비관리':'systems','장애관리':'faults','성능관리':'performance','연동관리':'cycle','보고서':'reports','운영관리':'users','설정':'settings'};
    const label=(item.querySelector('span:last-child')||item).textContent.trim();
    parent.postMessage({source:'tnms-planner',type:'navigate',key:keyMap[label]||'dashboard'},location.origin);
  });
});
