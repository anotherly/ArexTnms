package kr.co.TRSolution.tnms.common.security;

import java.sql.Connection;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.ibatis.executor.statement.StatementHandler;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Plugin;
import org.apache.ibatis.plugin.Signature;
import org.apache.ibatis.reflection.MetaObject;
import org.apache.ibatis.reflection.SystemMetaObject;

/**
 * 로그인 요청에서 지정된 5개 시스템 외의 행이 SQL 집계에 들어가지 않게 테이블 단위로 차단합니다.
 * 화면에서 감추는 필터가 아닌 DB SELECT의 FROM/JOIN에 적용되며 엑셀/집계도 포함합니다.
 * mapper WHERE 조건이나 JS 필터만으로 보호하면 우회 조회할 수 있어 적용한 공통 안전망입니다.
 * 인증이 없는 배치 호출은 기존 로직 유지. SQL 파라미터는 그대로 보존합니다.
 */
@Intercepts({@Signature(type = StatementHandler.class, method = "prepare", args = {Connection.class, Integer.class})})
public class SystemScopeSqlInterceptor implements Interceptor {
    private static final Pattern TABLE = Pattern.compile(
        "(?i)\\b(FROM|JOIN)\\s+`?(eqpmnt_info|link_sys_info|dsblty_info|link_raw_data|clct_cycle_info|clct_excn_hstry|thrshld_info|perf_raw_data|perf_hr_stats|perf_day_stats|eqpmnt_perf_stts|eqpmnt_stts|vw_eqpmnt_main_stts|eqpmnt_clsf_info|dsblty_type_info|dsblty_exprs_info|pids_eqpmnt_lse_rel|dsblty_excp_group_eqpmnt_idct_rel|dsblty_actn_hstry|dsblty_excp_group_info|dsblty_excp_schdl_info|dsblty_excp_group_eqpmnt_rel|dsblty_excp_schdl_grd_rel|enex_evnt_hstry)`?(?![A-Za-z0-9_])");
    private static final Set<String> CODES = new java.util.HashSet<String>(Arrays.asList("EMS_TX", "SCADA_SEC", "VMS", "PBX", "EMS_PIDS"));
    private static final Map<String,String> RULES = rules();
    private static final Pattern NEXT_WORD = Pattern.compile("^\\s+([A-Za-z_][A-Za-z0-9_]*)");
    private static final Set<String> SQL_KEYWORDS = new java.util.HashSet<String>(Arrays.asList(
        "WHERE", "ON", "LEFT", "RIGHT", "INNER", "OUTER", "JOIN", "CROSS", "GROUP", "ORDER",
        "LIMIT", "HAVING", "UNION", "OFFSET", "FOR", "LOCK", "STRAIGHT_JOIN", "USE", "FORCE"));

    private static Map<String,String> rules() {
        Map<String,String> m = new HashMap<String,String>();
        for (String name : Arrays.asList("eqpmnt_info","link_sys_info","link_raw_data","clct_cycle_info","eqpmnt_clsf_info","dsblty_exprs_info"))
            m.put(name, "_TNMS_SCOPE.LINK_SYS_CD IN (%s)");
        m.put("clct_excn_hstry", "EXISTS (SELECT 1 FROM clct_cycle_info _TNMS_ALLOW_C WHERE _TNMS_ALLOW_C.CLCT_CYCLE_SN = _TNMS_SCOPE.CLCT_CYCLE_SN AND _TNMS_ALLOW_C.LINK_SYS_CD IN (%s))");
        m.put("thrshld_info", "(_TNMS_SCOPE.LINK_SYS_CD IS NULL OR _TNMS_SCOPE.LINK_SYS_CD IN (%s))");
        m.put("dsblty_type_info", "(_TNMS_SCOPE.LINK_SYS_CD IS NULL OR _TNMS_SCOPE.LINK_SYS_CD IN (%s))");
        m.put("pids_eqpmnt_lse_rel", "EXISTS (SELECT 1 FROM eqpmnt_info _TNMS_ALLOW_E WHERE _TNMS_ALLOW_E.EQPMNT_SN = _TNMS_SCOPE.EQPMNT_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_excp_group_eqpmnt_idct_rel", "EXISTS (SELECT 1 FROM eqpmnt_info _TNMS_ALLOW_E WHERE _TNMS_ALLOW_E.EQPMNT_SN = _TNMS_SCOPE.EQPMNT_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        for (String name : Arrays.asList("perf_raw_data","perf_hr_stats","perf_day_stats","eqpmnt_perf_stts","eqpmnt_stts","vw_eqpmnt_main_stts","enex_evnt_hstry"))
            m.put(name, "EXISTS (SELECT 1 FROM eqpmnt_info _TNMS_ALLOW_E WHERE _TNMS_ALLOW_E.EQPMNT_SN = _TNMS_SCOPE.EQPMNT_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_info", "EXISTS (SELECT 1 FROM eqpmnt_info _TNMS_ALLOW_E WHERE _TNMS_ALLOW_E.EQPMNT_SN = _TNMS_SCOPE.EQPMNT_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_actn_hstry", "EXISTS (SELECT 1 FROM dsblty_info _TNMS_ALLOW_D JOIN eqpmnt_info _TNMS_ALLOW_E ON _TNMS_ALLOW_E.EQPMNT_SN=_TNMS_ALLOW_D.EQPMNT_SN WHERE _TNMS_ALLOW_D.DSBLTY_NO = _TNMS_SCOPE.DSBLTY_NO AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_excp_group_eqpmnt_rel", "EXISTS (SELECT 1 FROM eqpmnt_info _TNMS_ALLOW_E WHERE _TNMS_ALLOW_E.EQPMNT_SN = _TNMS_SCOPE.EQPMNT_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_excp_group_info", "EXISTS (SELECT 1 FROM dsblty_excp_group_eqpmnt_rel _TNMS_ALLOW_R JOIN eqpmnt_info _TNMS_ALLOW_E ON _TNMS_ALLOW_E.EQPMNT_SN=_TNMS_ALLOW_R.EQPMNT_SN WHERE _TNMS_ALLOW_R.EXCP_GROUP_SN = _TNMS_SCOPE.EXCP_GROUP_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_excp_schdl_info", "EXISTS (SELECT 1 FROM dsblty_excp_group_eqpmnt_rel _TNMS_ALLOW_R JOIN eqpmnt_info _TNMS_ALLOW_E ON _TNMS_ALLOW_E.EQPMNT_SN=_TNMS_ALLOW_R.EQPMNT_SN WHERE _TNMS_ALLOW_R.EXCP_GROUP_SN = _TNMS_SCOPE.EXCP_GROUP_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        m.put("dsblty_excp_schdl_grd_rel", "EXISTS (SELECT 1 FROM dsblty_excp_schdl_info _TNMS_ALLOW_S JOIN dsblty_excp_group_eqpmnt_rel _TNMS_ALLOW_R ON _TNMS_ALLOW_R.EXCP_GROUP_SN=_TNMS_ALLOW_S.EXCP_GROUP_SN JOIN eqpmnt_info _TNMS_ALLOW_E ON _TNMS_ALLOW_E.EQPMNT_SN=_TNMS_ALLOW_R.EQPMNT_SN WHERE _TNMS_ALLOW_S.EXCP_SCHDL_SN = _TNMS_SCOPE.EXCP_SCHDL_SN AND _TNMS_ALLOW_E.LINK_SYS_CD IN (%s))");
        return m;
    }

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        Set<String> allowed = SystemDataScope.current();
        if (allowed != null && allowed.size() < CODES.size()) {
            MetaObject meta = SystemMetaObject.forObject(invocation.getTarget());
            MappedStatement mapped = (MappedStatement) meta.getValue("delegate.mappedStatement");
            String id = mapped == null ? "" : mapped.getId();
            if (!(id.contains(".tnms.monitoring.mapper.") || id.contains(".tnms.performance.mapper.") ||
                  id.contains(".tnms.fault.mapper.") || id.contains(".tnms.report.mapper.")))
                return invocation.proceed();
            BoundSql boundSql = (BoundSql) meta.getValue("delegate.boundSql");
            String sql = boundSql.getSql();
            if (sql != null && sql.trim().toUpperCase(java.util.Locale.ROOT).startsWith("SELECT")) {
                String filteredSql = filterSql(sql, allowed);
                if (!sql.equals(filteredSql)) meta.setValue("delegate.boundSql.sql", filteredSql);
            }
        }
        return invocation.proceed();
    }

    static String filterSql(String sql, Set<String> allowed) {
        StringBuilder in = new StringBuilder();
        for (String code : Arrays.asList("EMS_TX","SCADA_SEC","VMS","PBX","EMS_PIDS")) {
            if (!allowed.contains(code)) continue;
            if (in.length() > 0) in.append(',');
            in.append('\'').append(code).append('\'');
        }
        if (in.length() == 0) in.append("'__NO_AUTHORIZED_SYSTEM__'");
        Matcher matcher = TABLE.matcher(sql);
        StringBuffer result = new StringBuffer();
        while (matcher.find()) {
            String table = matcher.group(2).toLowerCase(java.util.Locale.ROOT);
            String condition = RULES.get(table);
            // Inner scope conditions explicitly qualify the isolated source table.
            // Add a fallback table alias only when the original SQL did not provide one.
            // Without it MariaDB rejects FROM (SELECT...) WHERE ... (derived table lacks alias).
            Matcher next = NEXT_WORD.matcher(sql.substring(matcher.end()));
            boolean hasAlias = next.find() && !SQL_KEYWORDS.contains(next.group(1).toUpperCase(java.util.Locale.ROOT));
            String replacement = matcher.group(1) + " (SELECT * FROM " + table + " _TNMS_SCOPE WHERE " +
                String.format(java.util.Locale.ROOT, condition, in.toString()) + ")" + (hasAlias ? "" : " AS " + table);
            matcher.appendReplacement(result, Matcher.quoteReplacement(replacement));
        }
        matcher.appendTail(result);
        return result.toString();
    }

    @Override
    public Object plugin(Object target) { return Plugin.wrap(target, this); }
    @Override
    public void setProperties(java.util.Properties properties) { }
}
