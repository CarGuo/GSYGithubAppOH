import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import hilog from '@ohos.hilog';

const TAG: string = 'AbilityTest';

export default function abilityTest(): void {
  describe('AbilityTest', () => {
    beforeAll(() => {
      hilog.info(0x0000, TAG, 'beforeAll');
    });

    beforeEach(() => {
      hilog.info(0x0000, TAG, 'beforeEach');
    });

    afterEach(() => {
      hilog.info(0x0000, TAG, 'afterEach');
    });

    afterAll(() => {
      hilog.info(0x0000, TAG, 'afterAll');
    });

    it('assertContain', 0, () => {
      const a: string = 'abc';
      const b: string = 'b';
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
  });
}
