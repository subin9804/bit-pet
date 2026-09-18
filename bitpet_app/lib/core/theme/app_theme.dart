import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTextStyles.fontFamily,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          // 브랜드 초록. Material 위젯이 알아서 쓰는 강조색이라 여기는 먹색이 아니라
          // 눌리는 색이어야 한다 (AppColors.primary 는 '강조된 먹색'이므로 쓰지 않는다).
          primary: AppColors.brandAction,
          onPrimary: Colors.white,
          primaryContainer: AppColors.brandTint,
          onPrimaryContainer: AppColors.brandTintInk,
          secondary: AppColors.brandTint,
          onSecondary: AppColors.brandTintInk,
          surface: AppColors.bg,
          onSurface: AppColors.ink,
          surfaceContainerHighest: AppColors.bgAlt,
          outline: AppColors.line,
          error: AppColors.error,
          onError: Colors.white,
        ),
        // 카드는 기본적으로 떠 있지 않다 — 선으로만 구분한다 (AppShadows 참고)
        cardTheme: const CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.heading,
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(
              color: AppColors.ink, size: AppIconSize.lg),
        ),
        // 아이콘 기본 크기는 20 (리스트·버튼·메뉴). 탭바·앱바만 24 로 따로 준다.
        iconTheme: const IconThemeData(
            color: AppColors.ink, size: AppIconSize.md),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.lg),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line),
          ),
          // 포커스는 브랜드색으로 — 어디에 입력 중인지가 색 하나로 읽힌다
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.brandAction, width: 1.5),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
          labelStyle: AppTextStyles.body.copyWith(color: AppColors.ink2),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.ink3),
          errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: AppColors.ink3,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            textStyle: AppTextStyles.button,
          ).copyWith(
            // 눌림 상태를 한 단계 어두운 브랜드색으로 — 기본 오버레이(흰 반투명)는
            // 초록 위에서 거의 안 보인다
            overlayColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.pressed)
                    ? AppColors.brandPressed
                    : null),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandAction,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            textStyle: AppTextStyles.button,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.line,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bg,
          selectedItemColor: AppColors.brandAction,
          unselectedItemColor: AppColors.ink3,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        // 칩은 알약이다 — 모양만으로 '고를 수 있는 것'이 읽힌다
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.bgAlt,
          selectedColor: AppColors.brandTint,
          side: const BorderSide(color: AppColors.line),
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.ink),
          secondaryLabelStyle:
              AppTextStyles.caption.copyWith(color: AppColors.brandTintInk),
          shape: const StadiumBorder(),
        ),
        // ── 여기부터가 '실제로 떠 있는 것'들이다 ──────────────────────────
        //
        // 카드는 위(elevation 0)에서 선으로만 구분한다. 그림자는 **덮은 것**에만 준다.
        // 예전엔 이것들도 전부 0 이라, 바텀시트가 올라와도 내용 위에 얹힌 게 아니라
        // 화면이 그냥 바뀐 것처럼 보였다 (무엇이 임시로 떠 있는지 읽히지 않았다).
        //
        // ⚠️ 머티리얼은 elevation 으로 그림자를 직접 그려서 `AppShadows.elev2` 를
        //    끼워 넣을 자리가 없다. 같은 무게를 elevation + shadowColor 로 낸다.
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.brandAction,
          foregroundColor: Colors.white,
          elevation: 6,
          focusElevation: 6,
          hoverElevation: 6,
          // 눌린 동안엔 가라앉는다 — 손가락 아래로 들어가는 느낌
          highlightElevation: 2,
          shape: CircleBorder(),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          modalElevation: 8,
          shadowColor: AppShadows.material,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: AppShadows.material,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          titleTextStyle: AppTextStyles.subheading,
          contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.toggleOn;
            }
            return AppColors.toggleOff;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.toggleOn;
            }
            return AppColors.toggleOff;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: AppColors.line, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.brandAction
                  : AppColors.toggleOff),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.brandAction,
          linearTrackColor: AppColors.line,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.ink3,
          indicatorColor: AppColors.brandAction,
          labelStyle: AppTextStyles.bodyBold,
          unselectedLabelStyle: AppTextStyles.body,
          dividerColor: AppColors.line,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.brandAction,
          selectionColor: AppColors.brandTint,
          selectionHandleColor: AppColors.brandAction,
        ),
      );

  static ThemeData get dark => light;
}
