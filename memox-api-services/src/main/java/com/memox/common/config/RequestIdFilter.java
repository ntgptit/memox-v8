package com.memox.common.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Gives every request an ID, in the MDC (so every log line carries it), in the response header and in error bodies,
 * and logs one line per request. Runs before Spring Security so that its log lines carry the ID too.
 */
@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {

    public static final String REQUEST_ID_HEADER = "X-Request-ID";

    public static final String REQUEST_ID_MDC_KEY = "requestId";

    /** No CR, LF or spaces: an inbound ID must not be able to forge a log line. */
    private static final Pattern ACCEPTED_REQUEST_ID = Pattern.compile("[A-Za-z0-9._-]{1,64}");

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String requestId = requestIdOf(request);
        long startNanos = System.nanoTime();
        MDC.put(REQUEST_ID_MDC_KEY, requestId);
        response.setHeader(REQUEST_ID_HEADER, requestId);
        boolean escaped = false;
        try {
            chain.doFilter(request, response);
        } catch (Throwable ex) {
            // The container turns this into a 500 after we return; the response still says 200 here.
            escaped = true;
            throw ex;
        } finally {
            long durationMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNanos);
            int status = escaped ? HttpServletResponse.SC_INTERNAL_SERVER_ERROR : response.getStatus();
            log.info("{} {} -> {} in {} ms", request.getMethod(), request.getRequestURI(), status, durationMillis);
            MDC.remove(REQUEST_ID_MDC_KEY);
        }
    }

    private static String requestIdOf(HttpServletRequest request) {
        String inbound = request.getHeader(REQUEST_ID_HEADER);
        if (inbound != null && ACCEPTED_REQUEST_ID.matcher(inbound).matches()) {
            return inbound;
        }
        return UUID.randomUUID().toString();
    }
}
