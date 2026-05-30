import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  ThemeManager,
  ThemeManagerImpl,
  ThemeMode,
  ThemePalette,
  LIGHT_PALETTE,
  DARK_PALETTE,
  SystemColorProvider,
} from '../../../main/ets/theme/ThemeManager';
import {
  EventBus,
  EVENT_THEME_CHANGED,
} from '../../../main/ets/utils/EventBus';

class MockSystemProvider implements SystemColorProvider {
  dark: boolean = false;

  setDark(dark: boolean): void {
    this.dark = dark;
  }

  isDark(): boolean {
    return this.dark;
  }
}

export default function ThemeManagerTest(): void {
  describe('ThemeManagerTest', (): void => {
    let mock: MockSystemProvider;
    let eventCount: number = 0;
    let off: (() => void) | null = null;

    beforeAll((): void => {
      mock = new MockSystemProvider();
    });

    beforeEach(async (): Promise<void> => {
      ThemeManager.reset();
      ThemeManager.setSystemProvider(mock);
      eventCount = 0;
      EventBus.removeAll(EVENT_THEME_CHANGED);
      off = EventBus.on(EVENT_THEME_CHANGED, (): void => {
        eventCount = eventCount + 1;
      });
      await ThemeManager.setMode('light');
      eventCount = 0;
    });

    afterEach((): void => {
      if (off !== null) {
        off();
        off = null;
      }
      EventBus.removeAll(EVENT_THEME_CHANGED);
    });

    afterAll((): void => {
      ThemeManager.reset();
      EventBus.removeAll(EVENT_THEME_CHANGED);
    });

    it('light_palette_should_match_default', 0, (): void => {
      expect(LIGHT_PALETTE.background).assertEqual('#F5F7FA');
      expect(LIGHT_PALETTE.primary).assertEqual('#24292e');
    });

    it('dark_palette_should_match_default', 0, (): void => {
      expect(DARK_PALETTE.background).assertEqual('#161B22');
      expect(DARK_PALETTE.primary).assertEqual('#0D1117');
    });

    it('palette_should_have_required_fields', 0, (): void => {
      expect(LIGHT_PALETTE.primary.length > 0).assertTrue();
      expect(LIGHT_PALETTE.primaryDark.length > 0).assertTrue();
      expect(LIGHT_PALETTE.background.length > 0).assertTrue();
      expect(LIGHT_PALETTE.card.length > 0).assertTrue();
      expect(LIGHT_PALETTE.text.length > 0).assertTrue();
      expect(LIGHT_PALETTE.textSecondary.length > 0).assertTrue();
      expect(LIGHT_PALETTE.divider.length > 0).assertTrue();
      expect(LIGHT_PALETTE.danger.length > 0).assertTrue();
      expect(LIGHT_PALETTE.accent.length > 0).assertTrue();
      expect(LIGHT_PALETTE.navBackground.length > 0).assertTrue();
    });

    it('setMode_dark_should_apply_dark_palette', 0, async (): Promise<void> => {
      await ThemeManager.setMode('dark');
      expect(ThemeManager.current().background).assertEqual(DARK_PALETTE.background);
      expect(ThemeManager.getMode()).assertEqual('dark');
    });

    it('setMode_light_should_apply_light_palette', 0, async (): Promise<void> => {
      await ThemeManager.setMode('dark');
      await ThemeManager.setMode('light');
      expect(ThemeManager.current().background).assertEqual(LIGHT_PALETTE.background);
    });

    it('setMode_should_emit_theme_changed_event', 0, async (): Promise<void> => {
      await ThemeManager.setMode('dark');
      expect(eventCount >= 1).assertTrue();
      await ThemeManager.setMode('light');
      expect(eventCount >= 2).assertTrue();
    });

    it('system_mode_with_mock_dark_should_use_dark_palette', 0, async (): Promise<void> => {
      mock.setDark(true);
      await ThemeManager.setMode('system');
      expect(ThemeManager.current().background).assertEqual(DARK_PALETTE.background);
    });

    it('system_mode_with_mock_light_should_use_light_palette', 0, async (): Promise<void> => {
      mock.setDark(false);
      await ThemeManager.setMode('system');
      expect(ThemeManager.current().background).assertEqual(LIGHT_PALETTE.background);
    });

    it('normalizeMode_should_handle_unknown_value', 0, (): void => {
      const m1: ThemeMode = ThemeManagerImpl.normalizeMode('dark');
      const m2: ThemeMode = ThemeManagerImpl.normalizeMode('system');
      const m3: ThemeMode = ThemeManagerImpl.normalizeMode('light');
      const m4: ThemeMode = ThemeManagerImpl.normalizeMode('foo');
      expect(m1).assertEqual('dark');
      expect(m2).assertEqual('system');
      expect(m3).assertEqual('light');
      expect(m4).assertEqual('light');
    });

    it('current_should_return_palette_object', 0, (): void => {
      const p: ThemePalette = ThemeManager.current();
      expect(p !== null && p !== undefined).assertTrue();
      expect(typeof p.background).assertEqual('string');
    });
  });
}
