package io.bitpet.common.legal;

import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * 웹에 공개하는 약관(resources/legal) 이 앱 원문(legal_documents.dart) 과 같은지.
 *
 * <p>사용자가 앱에서 동의한 문장과 tailog.me/legal 에 걸린 문장이 다르면 동의 기록의 근거가
 * 흔들린다. 앱 약관을 고쳤다면 resources/legal/{id}.txt 를 같이 고치고
 * {@code AgreementType} 버전도 올린다. 서버만 따로 체크아웃한 환경에서는 건너뛴다.
 */
class LegalDocumentsSyncTest {

    private static final Path DART = Path.of("../bitpet_app/lib/core/legal/legal_documents.dart");

    @Test
    void server_copies_match_app_originals() throws Exception {
        assumeTrue(Files.exists(DART), "앱 소스가 없는 체크아웃");
        String dart = Files.readString(DART, StandardCharsets.UTF_8).replace("\r\n", "\n");
        String operatorInfo = group(dart, "const _operatorInfo = '''\n(.*?)''';");

        LegalPageController.DOCS.forEach((id, doc) -> {
            String block = group(dart, "id: '" + Pattern.quote(id) + "',(.*?)\n\\);");
            String body = group(block, "body: '''\n(.*?)''',").replace("$_operatorInfo", operatorInfo);

            assertThat(LegalPageController.text(id).replace("\r\n", "\n"))
                    .as("resources/legal/%s.txt", id).isEqualTo(body);
            assertThat(group(block, "effectiveDate: '([0-9-]+)'"))
                    .as("%s 시행일 ↔ AgreementType.%s", id, doc.type()).isEqualTo(doc.type().currentVersion());
            assertThat(group(block, "title: '([^']+)'")).as("%s 제목", id).isEqualTo(doc.title());
        });
    }

    private static String group(String source, String regex) {
        Matcher m = Pattern.compile(regex, Pattern.DOTALL).matcher(source);
        assertThat(m.find()).as("패턴 %s", regex).isTrue();
        return m.group(1);
    }
}
