(function(g){
  function enc(o){const p=new URLSearchParams();Object.keys(o||{}).forEach(k=>{const v=o[k];if(v!==undefined&&v!==null&&v!=='')p.append(k,v);});return p.toString();}
  g.mgmtGet=function(path,params){const q=enc(params);return api(path+(q?'?'+q:''));};
  g.mgmtPost=function(path,params){return api(path,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8'},body:enc(params)});};
  g.mgmtE=function(v){return escapeHtml(v==null?'':v)};
  g.mgmtVal=function(v,d){return v==null||v===''?(d==null?'-':d):v;};
  function mgmtKstText(ms){
    const d=new Date(Number(ms)+9*60*60*1000);
    if(isNaN(d.getTime()))return null;
    const z=n=>String(n).padStart(2,'0');
    return d.getUTCFullYear()+'-'+z(d.getUTCMonth()+1)+'-'+z(d.getUTCDate())+' '+z(d.getUTCHours())+':'+z(d.getUTCMinutes());
  }
  function mgmtDateValue(v){
    if(v===undefined||v===null||v==='')return null;
    if(v instanceof Date)return isNaN(v.getTime())?null:{text:mgmtKstText(v.getTime())};
    const s=String(v).trim();
    if(/^\d{10,13}$/.test(s)){
      let n=Number(s);
      if(s.length===10)n*=1000;
      const text=mgmtKstText(n);
      return text?{text:text}:null;
    }
    const m=s.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?/);
    if(m){
      return {text:m[1]+'-'+String(m[2]).padStart(2,'0')+'-'+String(m[3]).padStart(2,'0')+' '+String(m[4]||0).padStart(2,'0')+':'+String(m[5]||0).padStart(2,'0')};
    }
    const d=new Date(v);
    if(isNaN(d.getTime()))return null;
    const text=mgmtKstText(d.getTime());
    return text?{text:text}:null;
  }
  function mgmtDateText(v,localInput){
    const d=mgmtDateValue(v);
    if(!d)return localInput?'':'-';
    const t=d.text.substring(0,16);
    return localInput?t.replace(' ','T'):t;
  }
  g.mgmtDt=function(v){return mgmtDateText(v,false);};
  g.mgmtNum=function(v,d){const n=Number(v);return Number.isFinite(n)?n:(d||0);};
  g.mgmtDuration=function(sec){sec=Math.max(0,Number(sec)||0);const d=Math.floor(sec/86400),h=Math.floor(sec%86400/3600),m=Math.floor(sec%3600/60),s=Math.floor(sec%60);return (d?d+'일 ':'')+(h?h+'시간 ':'')+(m?m+'분 ':(!d&&!h?'0분 ':''))+s+'초';};
  g.mgmtGradeName=function(c,n){return n||({EMERGENCY:'긴급',CRITICAL:'심각',HIGH:'높음',LOW:'낮음',CAUTION:'주의',WARNING:'경고',INFO:'정보',CLEAR:'해제'}[c]||c||'-');};
  g.mgmtGradeClass=function(c){if(c==='EMERGENCY'||c==='CRITICAL')return 'bad';if(c==='HIGH')return 'high';if(c==='LOW'||c==='CAUTION'||c==='WARNING')return 'warn';if(c==='INFO')return 'info';return 'off';};
  g.mgmtBadge=function(name,cl){return '<span class="mgmt-badge '+(cl||'')+'">'+mgmtE(name)+'</span>';};
  g.mgmtYN=function(v){return mgmtBadge(v==='Y'?'사용':'미사용',v==='Y'?'':'off');};
  g.mgmtOptions=function(rows,valKey,textKey,selected,first){let h=first===undefined?'':('<option value="">'+mgmtE(first)+'</option>');(rows||[]).forEach(r=>{const v=r[valKey],t=r[textKey];h+='<option value="'+mgmtE(v)+'" '+(String(v)===String(selected)?'selected':'')+'>'+mgmtE(t)+'</option>';});return h;};
  g.mgmtLineChart=function(rows,defs){rows=rows||[];defs=defs||[];if(!rows.length)return '<div class="mgmt-empty">조회된 추이 데이터가 없습니다.</div>';const W=900,H=250,p=15;let max=0;rows.forEach(r=>defs.forEach(d=>max=Math.max(max,Number(r[d.key])||0)));max=Math.max(1,max);let svg='<div class="mgmt-chart"><svg viewBox="0 0 '+W+' '+H+'" preserveAspectRatio="none">';defs.forEach((d,di)=>{let pts=[];rows.forEach((r,i)=>{const x=p+(W-p*2)*(rows.length===1?.5:i/(rows.length-1));const y=H-p-(H-p*2)*(Number(r[d.key])||0)/max;pts.push(x.toFixed(1)+','+y.toFixed(1));});svg+='<polyline points="'+pts.join(' ')+'" fill="none" stroke="'+(d.stroke||['#2878e2','#2ab5a9','#e1a032'][di%3])+'" stroke-width="3" vector-effect="non-scaling-stroke" />';});svg+='</svg></div><div class="mgmt-chart-labels">';const take=Math.min(6,rows.length);for(let i=0;i<take;i++){const idx=Math.round(i*(rows.length-1)/Math.max(1,take-1));svg+='<span>'+mgmtE(rows[idx].timeLabel||rows[idx].hourLabel||'')+'</span>';}return svg+'</div>';};
  g.mgmtBars=function(rows){if(!rows||!rows.length)return '<div class="mgmt-empty">수집 실행 데이터가 없습니다.</div>';let max=1;rows.forEach(r=>max=Math.max(max,Number(r.successNocs||0)+Number(r.failNocs||0)));return '<div class="mgmt-bars">'+rows.map(r=>{const total=Number(r.successNocs||0)+Number(r.failNocs||0);const cls=Number(r.failNocs||0)>0?'warn':'';return '<i class="'+cls+'" title="'+mgmtE((r.hourLabel||'')+'시 성공 '+(r.successNocs||0)+' / 실패 '+(r.failNocs||0))+'" style="height:'+Math.max(4,total/max*100)+'%"></i>';}).join('')+'</div>';};
  g.mgmtToday=function(offset){const d=new Date();d.setDate(d.getDate()+(offset||0));const z=n=>String(n).padStart(2,'0');return d.getFullYear()+'-'+z(d.getMonth()+1)+'-'+z(d.getDate());};
  g.mgmtLocalInput=function(v){return mgmtDateText(v,true);};
  g.mgmtCsv=function(filename,headers,rows){const esc=v=>'"'+String(v==null?'':v).replace(/"/g,'""')+'"';const text='\ufeff'+[headers.map(h=>esc(h.label)).join(','),...(rows||[]).map(r=>headers.map(h=>esc(typeof h.value==='function'?h.value(r):r[h.value])).join(','))].join('\r\n');const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([text],{type:'text/csv;charset=utf-8'}));a.download=filename;a.click();setTimeout(()=>URL.revokeObjectURL(a.href),500);};
})(window);
