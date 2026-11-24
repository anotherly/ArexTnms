package kr.co.TRSolution.tnms.gateway.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import kr.co.TRSolution.tnms.gateway.mapper.SystemCodeMapper;

/** WEB 연계시스템 코드와 게이트웨이 EMS ID의 유일한 연결 지점 (CD_DVIC). */
@Service("systemCodeRegistry")
public class SystemCodeRegistry {
    @Resource(name="systemCodeMapper") private SystemCodeMapper mapper;

    private static final String REQUEST_CACHE="TNMS_SYSTEM_CODE_MAPPING";
    @SuppressWarnings("unchecked")
    public Map<Integer,String> emsToCodes() {
        RequestAttributes attrs=RequestContextHolder.getRequestAttributes();
        if(attrs!=null) {
            Object cached=attrs.getAttribute(REQUEST_CACHE,RequestAttributes.SCOPE_REQUEST);
            if(cached instanceof Map) return (Map<Integer,String>)cached;
        }
        Map<Integer,String> result = new LinkedHashMap<Integer,String>();
        for (Map<String,Object> row : mapper.selectSystemMappings()) {
            Number id=(Number)row.get("emsId");
            String code=(String)row.get("linkSysCd");
            if(id==null || code==null || code.isEmpty()) continue;
            String prior=result.put(Integer.valueOf(id.intValue()),code);
            if(prior!=null) throw new IllegalStateException("EMS ID의 공통코드 매핑 중복: "+id);
        }
        if(result.size()!=5) throw new IllegalStateException("CD_DVIC 시스템 매핑은 5개여야 합니다. 확인된 수: "+result.size());
        Map<Integer,String> snapshot=java.util.Collections.unmodifiableMap(result);
        if(attrs!=null)attrs.setAttribute(REQUEST_CACHE,snapshot,RequestAttributes.SCOPE_REQUEST);
        return snapshot;
    }
    public String codeForEms(int emsId) { return emsToCodes().get(Integer.valueOf(emsId)); }
    public int emsForCode(String code) {
        for(Map.Entry<Integer,String> pair:emsToCodes().entrySet())
            if(pair.getValue().equals(code))return pair.getKey().intValue();
        throw new IllegalArgumentException("등록되지 않은 연계시스템 코드입니다: "+code);
    }
    public Set<String> allCodes() {return new LinkedHashSet<String>(emsToCodes().values());}
    public List<Integer> allowedEmsIds(Set<String> allowed) {
        List<Integer> ids=new ArrayList<Integer>();
        for(Map.Entry<Integer,String> entry:emsToCodes().entrySet())
            if(allowed==null || allowed.contains(entry.getValue()))ids.add(entry.getKey());
        if(ids.isEmpty())ids.add(Integer.valueOf(-1)); // IN() 또는 무권한 전체조회 방지
        return ids;
    }
}
