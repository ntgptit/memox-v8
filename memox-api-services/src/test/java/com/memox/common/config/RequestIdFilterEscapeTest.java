package com.memox.common.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.slf4j.MDC;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

/** An exception that escapes the chain must not be logged as the servlet's default 200. */
@ExtendWith(OutputCaptureExtension.class)
class RequestIdFilterEscapeTest {

    @Test
    void escapingExceptionIsLoggedAsServerErrorAndTheMdcIsCleared(CapturedOutput output) {
        RequestIdFilter filter = new RequestIdFilter();
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/probe/escape");
        MockHttpServletResponse response = new MockHttpServletResponse();

        assertThatThrownBy(() -> filter.doFilter(request, response, (req, res) -> {
                    throw new ServletException("escaped");
                }))
                .isInstanceOf(ServletException.class);

        assertThat(output.getOut()).contains("GET /probe/escape -> 500 in ");
        assertThat(MDC.get(RequestIdFilter.REQUEST_ID_MDC_KEY)).isNull();
    }
}
