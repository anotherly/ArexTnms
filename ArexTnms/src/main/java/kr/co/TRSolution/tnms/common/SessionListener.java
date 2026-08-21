package kr.co.TRSolution.tnms.common;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

public class SessionListener implements HttpSessionListener {
    private static final Map<String, HttpSession> USER_SESSIONS = new ConcurrentHashMap<String, HttpSession>();
    private static final Map<String, String> SESSION_USERS = new ConcurrentHashMap<String, String>();

    public static void register(String userId, HttpSession session) {
        HttpSession oldSession = USER_SESSIONS.put(userId, session);
        SESSION_USERS.put(session.getId(), userId);
        if (oldSession != null && !oldSession.getId().equals(session.getId())) {
            SESSION_USERS.remove(oldSession.getId());
            try { oldSession.invalidate(); } catch (IllegalStateException ignored) { }
        }
    }

    public static void unregister(HttpSession session) {
        String userId = SESSION_USERS.remove(session.getId());
        if (userId != null) USER_SESSIONS.remove(userId, session);
    }

    @Override
    public void sessionCreated(HttpSessionEvent event) { }

    @Override
    public void sessionDestroyed(HttpSessionEvent event) {
        unregister(event.getSession());
    }
}
