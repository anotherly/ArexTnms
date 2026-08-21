package kr.co.TRSolution.tnms.audit.service;

import kr.co.TRSolution.tnms.user.vo.UserVO;

public interface AuditService {
    void record(UserVO user, String ip, String menu, String action,
                String target, String message, String result);
}
