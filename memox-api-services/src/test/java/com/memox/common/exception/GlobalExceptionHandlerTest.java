package com.memox.common.exception;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@WebMvcTest(controllers = ExceptionProbeController.class)
@AutoConfigureMockMvc(addFilters = false)
class GlobalExceptionHandlerTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void businessExceptionUsesItsCodeAndStatus() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/business")), 404, "PROBE_NOT_FOUND")
			.andExpect(jsonPath("$.detail").value("Probe 42 was not found."))
			.andExpect(jsonPath("$.instance").value("/probe/business"));
	}

	@Test
	void invalidBodyListsFieldErrors() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"\"}")),
				400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("name"))
			.andExpect(jsonPath("$.errors[0].message").isNotEmpty());
	}

	@Test
	void invalidRequestParamListsParameterErrors() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/param").param("size", "0")), 400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("size"));
	}

	@Test
	void constraintViolationListsFieldErrors() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/constraint")), 400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("name"));
	}

	@Test
	void malformedJsonIsBadRequest() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.APPLICATION_JSON).content("{")), 400,
				"BAD_REQUEST");
	}

	@Test
	void wrongMethodIsMethodNotAllowed() throws Exception {
		expectProblem(mockMvc.perform(delete("/probe/business")), 405, "METHOD_NOT_ALLOWED");
	}

	@Test
	void wrongContentTypeIsUnsupportedMediaType() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.TEXT_PLAIN).content("name")), 415,
				"UNSUPPORTED_MEDIA_TYPE");
	}

	@Test
	void unknownPathIsNotFound() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/does-not-exist")), 404, "NOT_FOUND");
	}

	@Test
	void dataIntegrityViolationIsConflictWithoutDatabaseDetails() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/conflict")), 409, "DATA_CONFLICT")
			.andExpect(content().string(not(containsString(ExceptionProbeController.LEAKED_CONSTRAINT))));
	}

	@Test
	void unexpectedExceptionIsInternalErrorWithoutLeakingIt() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/boom")), 500, "INTERNAL_ERROR")
			.andExpect(content().string(not(containsString(ExceptionProbeController.LEAKED_SQL))))
			.andExpect(content().string(not(containsString("IllegalStateException"))));
	}

	private ResultActions expectProblem(ResultActions result, int status, String code) throws Exception {
		return result.andExpect(status().is(status))
			.andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
			.andExpect(jsonPath("$.status").value(status))
			.andExpect(jsonPath("$.code").value(code));
	}

}
