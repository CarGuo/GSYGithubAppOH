/**
 * PhotoPage —— L6.4 大图预览
 *
 * RN 基准 [PhotoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PhotoPage.js)：
 *   - 单图全屏（react-native-image-zoom-viewer）
 *   - backgroundColor=primaryColor
 *   - 点击空白 → Actions.pop()
 *   - 失败显示 default_img.png
 *   - onSaveToCamera 占位
 *
 * OH 端 v1（M-stub）：
 *   - 全屏 Stack + Image objectFit:Contain
 *   - 点击 → NavigationService.pop
 *   - 长按 → CommonToast「保存到相册（M-stub）」
 *   - 入口参数：{ uri: string }（与 RN 字段对齐）
 *   - boot 通道：want.parameters.bootPhoto=<url>
 */
import { NavigationService } from '../navigation/NavigationService';
import { RouteParamStore } from '../navigation/RouteParamStore';
import { RouteName } from '../navigation/Routes';
import { BOOT_PHOTO_KEY } from '../entryability/EntryAbility';
import { GSYColor, GSYFontSize, GSYIconSize } from '../style/Theme';
import { CommonToast } from '../common/CommonToast';
import { Logger } from '../ai-debug/Logger';

interface PhotoPageRouteParam {
  uri: string;
}

const FALLBACK_URI: string = '';

@Component
export struct PhotoPage {
  @State uri: string = '';
  @State loading: boolean = true;
  @State failed: boolean = false;
  private exit: boolean = false;

  aboutToAppear(): void {
    this.applyRouterParams();
    Logger.i('boot/ts', `PhotoPage.aboutToAppear t=${Date.now()} uri='${this.uri}'`);
  }

  private resolveUriFromObject(raw: Object | undefined | null): string {
    if (raw === undefined || raw === null) {
      return FALLBACK_URI;
    }
    const obj: PhotoPageRouteParam = raw as PhotoPageRouteParam;
    if (obj.uri !== undefined && obj.uri !== null && obj.uri.length > 0) {
      return obj.uri;
    }
    return FALLBACK_URI;
  }

  private applyRouterParams(): void {
    // 优先级 1：RouteParamStore（NavigationService.push 同步写入，覆盖所有 push 入口）
    const routeRaw: Object | null = RouteParamStore.consume(RouteName.Photo);
    if (routeRaw !== null) {
      const resolvedFromRoute: string = this.resolveUriFromObject(routeRaw);
      if (resolvedFromRoute.length > 0) {
        this.uri = resolvedFromRoute;
        Logger.i('photo/route', `PhotoPage adopted via RouteParamStore uri='${resolvedFromRoute}'`);
        return;
      }
    }
    const stack: NavPathStack | null = NavigationService.getStack();
    if (stack !== null) {
      try {
        const names: string[] = stack.getAllPathName();
        if (names.length > 0) {
          const idx: number = names.length - 1;
          const raw: Object | undefined = stack.getParamByIndex(idx) as Object | undefined;
          const resolved: string = this.resolveUriFromObject(raw === undefined ? null : raw);
          if (resolved.length > 0) {
            this.uri = resolved;
            return;
          }
        }
      } catch (_e) {
      }
    }
    if (this.uri.length === 0) {
      const bootPhoto: string | undefined = AppStorage.get<string>(BOOT_PHOTO_KEY);
      if (bootPhoto !== undefined && bootPhoto !== null && bootPhoto.length > 0) {
        this.uri = bootPhoto;
      }
    }
  }

  private dismiss(): void {
    if (this.exit) {
      return;
    }
    this.exit = true;
    Logger.i('boot/ts', `PhotoPage.dismiss t=${Date.now()}`);
    NavigationService.pop();
  }

  build(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.uri.length > 0 && !this.failed) {
        Image(this.uri)
          .id('photo_image')
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .onComplete((): void => {
            this.loading = false;
          })
          .onError((): void => {
            this.loading = false;
            this.failed = true;
          });
      }

      if (this.loading) {
        LoadingProgress()
          .id('photo_loading')
          .width(GSYIconSize.large)
          .height(GSYIconSize.large)
          .color(GSYColor.white);
      }

      if (this.failed) {
        Text('图片加载失败')
          .id('photo_failed')
          .fontColor(GSYColor.white)
          .fontSize(GSYFontSize.middleNormal);
      }
    }
    .id('photo_page_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.primary)
    .onClick((): void => {
      this.dismiss();
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction((): void => {
          Logger.i('boot/ts', `PhotoPage.longPress t=${Date.now()}`);
          CommonToast.showShort('保存到相册（M-stub）');
        })
    );
  }
}
