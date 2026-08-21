package kr.co.TRSolution.tnms.common.util;

import javax.servlet.http.HttpServletRequest;

public final class ClientIpUtil {
    private ClientIpUtil() { }

    public static String getClientIp(HttpServletRequest request) {
        String[] headers = {"X-Forwarded-For", "Proxy-Client-IP", "WL-Proxy-Client-IP"};
        for (String header : headers) {
            String value = request.getHeader(header);
            if (value != null && value.length() > 0 && !"unknown".equalsIgnoreCase(value)) {
                int comma = value.indexOf(',');
                return fitIpv4(comma > -1 ? value.substring(0, comma).trim() : value.trim());
            }
        }
        return fitIpv4(request.getRemoteAddr());
    }

    private static String fitIpv4(String ip) {
        if (ip == null) return null;
        if ("0:0:0:0:0:0:0:1".equals(ip)) return "127.0.0.1";
        return ip.length() > 15 ? ip.substring(0, 15) : ip;
    }
}
