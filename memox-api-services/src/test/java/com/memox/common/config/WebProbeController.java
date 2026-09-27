package com.memox.common.config;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Test-only endpoints for the full-context web tests. The paths stay under {@code /probe} because component scanning
 * puts this controller in every full-context test.
 */
@RestController
@RequestMapping("/probe")
public class WebProbeController {

    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }

    @GetMapping("/conflict")
    public void conflict() {
        throw new BusinessException(ErrorCode.CONFLICT);
    }

    @PostMapping("/echo")
    public String echo(@RequestBody String body) {
        return body;
    }
}
