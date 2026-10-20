package kr.co.TRSolution.tnms.audit.service;

import java.util.List;

import kr.co.TRSolution.tnms.audit.vo.AuditVO;

import kr.co.TRSolution.tnms.user.vo.UserVO;

public interface AuditService {
    void record(UserVO user, String ip, String menu, String action,
                String target, String message, String result);
    List<AuditVO> selectJobLogList(AuditVO searchVO);
    AuditVO selectJobLog(Long jobLogSn);
}
