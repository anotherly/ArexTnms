package kr.co.TRSolution.tnms.audit.mapper;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.audit.vo.AuditVO;

@Mapper("auditMapper")
public interface AuditMapper {
    int insertJobLog(AuditVO auditVO);
}
