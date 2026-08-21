package kr.co.TRSolution.tnms.audit.service.impl;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import kr.co.TRSolution.tnms.audit.mapper.AuditMapper;
import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.audit.vo.AuditVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Service("auditService")
public class AuditServiceImpl implements AuditService {
    private static final Logger logger = LoggerFactory.getLogger(AuditServiceImpl.class);

    @Resource(name = "auditMapper")
    private AuditMapper auditMapper;

    @Override
    public void record(UserVO user, String ip, String menu, String action,
                       String target, String message, String result) {
        AuditVO audit = new AuditVO();
        if (user != null) {
            audit.setUserSn(user.getUserSn());
            audit.setUserId(user.getUserId());
        }
        audit.setUserIpAddr(ip);
        audit.setCntnMenuNm(menu);
        audit.setJobSeCd(action);
        audit.setTrgtKeyVal(target);
        audit.setLogCn(message);
        audit.setJobRsltCd(result);
        try {
            auditMapper.insertJobLog(audit);
        } catch (RuntimeException e) {
            logger.warn("작업로그 저장 실패", e);
        }
    }
}
