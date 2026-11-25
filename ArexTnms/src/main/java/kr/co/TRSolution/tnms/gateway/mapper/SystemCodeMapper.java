package kr.co.TRSolution.tnms.gateway.mapper;

import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;

/** CD_DVIC.GW_CD(EMS ID)와 기존 WEB LINK_SYS_CD의 DB 관계 조회. */
@Mapper("systemCodeMapper")
public interface SystemCodeMapper {
    List<Map<String,Object>> selectSystemMappings();
}
