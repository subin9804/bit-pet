package io.bitpet.routine.domain;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.Collections;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.stream.Collectors;

/**
 * 정수 집합 ↔ CSV 문자열 ('1,3,5'). 비어 있으면 NULL 로 저장한다 —
 * DB CHECK 가 빈 문자열을 형식 위반으로 보고, '선택 없음'과 '칸을 안 씀'을 구분할 이유가 없다.
 */
@Converter
public class IntSetCsvConverter implements AttributeConverter<SortedSet<Integer>, String> {

    @Override
    public String convertToDatabaseColumn(SortedSet<Integer> values) {
        if (values == null || values.isEmpty()) return null;
        return values.stream().map(String::valueOf).collect(Collectors.joining(","));
    }

    @Override
    public SortedSet<Integer> convertToEntityAttribute(String csv) {
        if (csv == null || csv.isBlank()) return Collections.emptySortedSet();
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::valueOf)
                .collect(Collectors.toCollection(TreeSet::new));
    }
}
