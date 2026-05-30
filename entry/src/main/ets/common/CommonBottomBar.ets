/**
 * CommonBottomBar —— 1:1 对齐 RN 端
 * [components/common/CommonBottomBar.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/common/CommonBottomBar.js)
 *
 * 通用横向按键控件，dataList 驱动 N 项；每项 = TouchableOpacity{ Icon + Text }，
 * 平均分配剩余空间（layoutWeight=1）。RN 端 paddingVertical=normalMarginEdge + shadowCard。
 *
 * RN 用 react-native-vector-icons/Octicons；OH 端无 Octicons，
 * 调用方需自行传入 [IconFont.ets](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/common/IconFont.ets) 暴露的 FontAwesome 码点字符串。
 */

import { GSYColor, GSYFontSize, GSYSpacing, GSYShadow } from '../style/Theme';
import { IconFont } from './IconFont';

const ITEM_ICON_SIZE: number = 14;
const ICON_TEXT_GAP: number = 10;
const REPO_ACTION_WIDTH: number = 78;
const REPO_ACTION_ICON_TEXT_GAP: number = 4;

export class CommonBottomBarItem {
  itemName: string = '';
  icon: string = '';
  iconColor: string = GSYColor.primary;
  itemTextColor: string = GSYColor.primary;
  itemClick: () => void = (): void => {};
  itemId: string = '';
}

@Component
export struct CommonBottomBar {
  @Prop @Watch('onDataListChanged') dataList: CommonBottomBarItem[] = [];
  rootId: string = 'common_bottom_bar';
  rootBackgroundColor: ResourceColor = GSYColor.white;
  rootMarginHorizontal: number = 0;
  rootMarginTop: number = 0;
  rootMarginBottom: number = 0;
  rootBorderRadius: number = 0;
  // 0 表示不显式约束（保持 wrap content）。
  // 历史教训：父侧若用 `.layoutWeight(1)` 给 Tabs 撑满，再放本组件兄弟节点时
  // 子项 Row .height('100%') 会向上传染撑垮 Tabs.layoutWeight(1)。
  // 调用方应主动传一个固定 height（与 RN CommonBottomBar 高度一致 ~ 50）。
  rootHeight: number = 0;
  showShadow: boolean = true;
  repoActionStyle: boolean = false;
  trailingItemId: string = 'branch';
  @State private dataListRev: number = 0;

  private onDataListChanged(): void {
    this.dataListRev++;
  }

  build(): void {
    Row() {
      ForEach(this.dataList, (item: CommonBottomBarItem, index: number): void => {
        if (this.repoActionStyle && item.itemId !== this.trailingItemId) {
          Column() {
            if (item.icon.length > 0) {
              IconFont({
                char: item.icon,
                glyphSize: ITEM_ICON_SIZE + 2,
                glyphColor: item.iconColor,
              });
            }
            Text(item.itemName)
              .id(item.itemId.length > 0
                ? 'common_bottom_bar_text_' + item.itemId
                : 'common_bottom_bar_text_' + index.toString())
              .margin({ top: REPO_ACTION_ICON_TEXT_GAP })
              .fontSize(GSYFontSize.min)
              .fontColor(item.itemTextColor)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .id(item.itemId.length > 0
            ? 'common_bottom_bar_item_' + item.itemId
            : 'common_bottom_bar_item_' + index.toString())
          .width(REPO_ACTION_WIDTH)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick((): void => {
            item.itemClick();
          });
        } else if (this.repoActionStyle) {
          Row() {
            Text(item.itemName)
              .id(item.itemId.length > 0
                ? 'common_bottom_bar_text_' + item.itemId
                : 'common_bottom_bar_text_' + index.toString())
              .fontSize(GSYFontSize.min)
              .fontColor(item.itemTextColor)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            if (item.icon.length > 0) {
              IconFont({
                char: item.icon,
                glyphSize: ITEM_ICON_SIZE,
                glyphColor: item.iconColor,
              })
                .margin({ left: 4 });
            }
          }
          .id(item.itemId.length > 0
            ? 'common_bottom_bar_item_' + item.itemId
            : 'common_bottom_bar_item_' + index.toString())
          .layoutWeight(1)
          .height('100%')
          .padding({ right: GSYSpacing.normalEdge })
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick((): void => {
            item.itemClick();
          });
        } else {
          Row() {
            if (item.icon.length > 0) {
              IconFont({
                char: item.icon,
                glyphSize: ITEM_ICON_SIZE,
                glyphColor: item.iconColor,
              });
            }
            Text(item.itemName)
              .id(item.itemId.length > 0
                ? 'common_bottom_bar_text_' + item.itemId
                : 'common_bottom_bar_text_' + index.toString())
              .margin({ left: ICON_TEXT_GAP })
              .fontSize(GSYFontSize.small)
              .fontColor(item.itemTextColor);
          }
          .id(item.itemId.length > 0
            ? 'common_bottom_bar_item_' + item.itemId
            : 'common_bottom_bar_item_' + index.toString())
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick((): void => {
            item.itemClick();
          });
        }
      }, (item: CommonBottomBarItem, index: number): string =>
        this.dataListRev.toString() + ':' + index.toString() + ':' + item.itemId + ':' + item.itemName + ':' + item.icon + ':' + item.iconColor + ':' + item.itemTextColor);
    }
    .id(this.rootId)
    .width('100%')
    .height(this.rootHeight > 0 ? this.rootHeight : GSYSpacing.bottomBarDefault)
    .padding({
      top: GSYSpacing.normalEdge,
      bottom: GSYSpacing.normalEdge,
    })
    .margin({
      left: this.rootMarginHorizontal,
      right: this.rootMarginHorizontal,
      top: this.rootMarginTop,
      bottom: this.rootMarginBottom,
    })
    .borderRadius(this.rootBorderRadius)
    .backgroundColor(this.rootBackgroundColor)
    .shadow(this.showShadow ? {
      radius: GSYShadow.radius,
      color: GSYColor.line,
      offsetX: 0,
      offsetY: -GSYShadow.elevation,
    } : undefined)
    .alignItems(VerticalAlign.Center);
  }
}
