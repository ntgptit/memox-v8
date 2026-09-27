package com.memox.common.type_handler;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

/**
 * Maps a {@link CodeEnum} to and from its database code. An unknown code fails loudly instead of reading as
 * {@code null}, and an enum whose constants share a code fails when the handler is built.
 *
 * @param <E> the enum type
 */
public abstract class BaseEnumTypeHandler<E extends Enum<E> & CodeEnum> extends BaseTypeHandler<E> {

    private final Class<E> enumType;

    private final Map<String, E> constantsByCode;

    protected BaseEnumTypeHandler(Class<E> enumType) {
        this.enumType = enumType;
        this.constantsByCode = Arrays.stream(enumType.getEnumConstants())
                .collect(Collectors.toUnmodifiableMap(E::getCode, Function.identity()));
    }

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, E parameter, JdbcType jdbcType) throws SQLException {
        ps.setString(i, parameter.getCode());
    }

    @Override
    public E getNullableResult(ResultSet rs, String columnName) throws SQLException {
        return toConstant(rs.getString(columnName));
    }

    @Override
    public E getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        return toConstant(rs.getString(columnIndex));
    }

    @Override
    public E getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        return toConstant(cs.getString(columnIndex));
    }

    private E toConstant(String code) {
        if (code == null) {
            return null;
        }
        E constant = constantsByCode.get(code);
        if (constant == null) {
            throw new IllegalArgumentException("Unknown " + enumType.getSimpleName() + " code: '" + code + "'");
        }
        return constant;
    }
}
