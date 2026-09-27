package com.memox.common.type_handler;

/**
 * An enum stored in the database by a short code instead of its name. Give each such enum a one-line
 * {@link BaseEnumTypeHandler} subclass in this package, annotated {@code @MappedTypes(TheEnum.class)}.
 */
public interface CodeEnum {

	String getCode();

}
