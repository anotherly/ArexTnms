package kr.co.TRSolution.tnms.audit.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.audit.vo.AuditVO;

@Mapper("auditMapper")
public interface AuditMapper {
    int insertJobLog(AuditVO auditVO);
    List<AuditVO> selectJobLogList(AuditVO searchVO);
    AuditVO selectJobLog(Long jobLogSn);
}
