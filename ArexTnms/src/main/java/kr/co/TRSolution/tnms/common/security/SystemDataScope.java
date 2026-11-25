package kr.co.TRSolution.tnms.common.security;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import javax.servlet.http.HttpServletRequest;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/** 서버측 요청별 5개 연계시스템 조회 범위. 브라우저 파라미터로 범위를 늘릴 수 없습니다. */
public final class SystemDataScope {
    public static final String REQUEST_ATTRIBUTE = "TNMS_ALLOWED_SYSTEM_CODES";
    public static final String ALL_SYSTEM_CODES = "TNMS_ALL_SYSTEM_CODES";
    private SystemDataScope() { }

    @SuppressWarnings("unchecked")
    public static Set<String> current() {
        RequestAttributes attrs = RequestContextHolder.getRequestAttributes();
        if (!(attrs instanceof ServletRequestAttributes)) return null; // 배치/스케줄러: 인터랙티브 사용자 없음
        HttpServletRequest req = ((ServletRequestAttributes) attrs).getRequest();
        Object value = req.getAttribute(REQUEST_ATTRIBUTE);
        if (value == null) return null; // 인증되지 않은 엔드포인트에서는 별도 인증 필터가 담당
        Set<String> selected = new HashSet<String>();
        if (value instanceof Collection) for (Object code : (Collection<?>) value) {
            if (code instanceof String && ((String)code).matches("[A-Z][A-Z0-9_]{1,19}")) selected.add((String) code);
        }
        return selected;
    }

    @SuppressWarnings("unchecked")
    public static boolean isLimited() {
        Set<String> allowed=current();
        RequestAttributes attrs=RequestContextHolder.getRequestAttributes();
        if(allowed==null || !(attrs instanceof ServletRequestAttributes)) return false;
        Object all=((ServletRequestAttributes)attrs).getRequest().getAttribute(ALL_SYSTEM_CODES);
        return !(all instanceof Collection) || !allowed.containsAll((Collection<String>)all);
    }

    public static void requireSystem(String systemCode) {
        Set<String> allowed = current();
        if (allowed != null && !allowed.contains(systemCode))
            throw new SecurityException("해당 연계시스템의 데이터에 접근할 권한이 없습니다.");
    }
}
