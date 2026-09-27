package com.memox.common.type_handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.apache.ibatis.type.JdbcType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class BaseEnumTypeHandlerTest {

    private static final String COLUMN = "status";

    private final SampleStatusTypeHandler handler = new SampleStatusTypeHandler();

    @Getter
    @RequiredArgsConstructor
    private enum DuplicateCode implements CodeEnum {
        FIRST("X"),

        SECOND("X");

        private final String code;
    }

    @Test
    void writesTheCodeNotTheName() throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);

        handler.setParameter(statement, 1, SampleStatus.ACTIVE, null);

        verify(statement).setString(1, "A");
    }

    @Test
    void writesNullAsSqlNull() throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);

        handler.setParameter(statement, 1, null, JdbcType.VARCHAR);

        verify(statement).setNull(1, Types.VARCHAR);
    }

    @Test
    void readsTheConstantForItsCodeByColumnName() throws Exception {
        ResultSet resultSet = mock(ResultSet.class);
        when(resultSet.getString(COLUMN)).thenReturn("I");

        assertThat(handler.getResult(resultSet, COLUMN)).isEqualTo(SampleStatus.INACTIVE);
    }

    @Test
    void readsTheConstantForItsCodeByColumnIndex() throws Exception {
        ResultSet resultSet = mock(ResultSet.class);
        when(resultSet.getString(1)).thenReturn("A");

        assertThat(handler.getResult(resultSet, 1)).isEqualTo(SampleStatus.ACTIVE);
    }

    @Test
    void readsTheConstantFromACallableStatement() throws Exception {
        CallableStatement statement = mock(CallableStatement.class);
        when(statement.getString(2)).thenReturn("A");

        assertThat(handler.getResult(statement, 2)).isEqualTo(SampleStatus.ACTIVE);
    }

    @Test
    void readsSqlNullAsNull() throws Exception {
        ResultSet resultSet = mock(ResultSet.class);
        when(resultSet.getString(COLUMN)).thenReturn(null);

        assertThat(handler.getResult(resultSet, COLUMN)).isNull();
    }

    @ParameterizedTest
    @ValueSource(strings = {"X", "a", "ACTIVE", ""})
    void rejectsAnUnknownCodeNamingTheEnum(String storedCode) throws Exception {
        ResultSet resultSet = mock(ResultSet.class);
        when(resultSet.getString(COLUMN)).thenReturn(storedCode);

        assertThatThrownBy(() -> handler.getResult(resultSet, COLUMN))
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("Unknown SampleStatus code: '" + storedCode + "'");
    }

    @Test
    void rejectsAnEnumWithDuplicateCodesWhenBuilt() {
        // Anonymous on purpose: MyBatis's handler package scan skips anonymous classes, so this deliberately broken
        // handler never reaches the MyBatisBaseIT context.
        assertThatThrownBy(() -> new BaseEnumTypeHandler<DuplicateCode>(DuplicateCode.class) {})
                .isInstanceOf(IllegalStateException.class);
    }
}
