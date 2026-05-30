import { AppBar, AppBarAction } from '../../../main/ets/common/AppBar';
import { CommonToast } from '../../../main/ets/common/CommonToast';
import { LoadingModal } from '../../../main/ets/common/LoadingModal';
import { CommonModal, CommonOptionItem, PromptDialog } from '../../../main/ets/common/CommonModal';
import {
  PullLoadMoreList,
  PullLoadMoreController,
  PullLoadMoreFooterState,
} from '../../../main/ets/common/PullLoadMoreList';

interface DemoItem {
  id: number;
  text: string;
}

@Entry
@Component
struct CommonComponentsPage {
  @State data: DemoItem[] = [
    { id: 1, text: 'Item 1' },
    { id: 2, text: 'Item 2' },
    { id: 3, text: 'Item 3' },
  ];
  @State plmController: PullLoadMoreController = new PullLoadMoreController();

  // PromptDialog 必须在 @Component 实例 build 上下文里 new CustomDialogController 才能弹。
  // 不能在 static 函数内 new（KI-046 已暴露过 → KI-047 收尾把 CommonModal.prompt 删掉）。
  private promptController: CustomDialogController = new CustomDialogController({
    builder: PromptDialog({
      title: 'Input',
      placeholder: 'something',
      okText: 'OK',
      cancelText: 'Cancel',
      onConfirm: (text: string): void => {
        CommonToast.showShort(text);
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
  });

  aboutToAppear(): void {
    this.plmController.setFooterState(PullLoadMoreFooterState.LOADING);
  }

  @Builder
  rowBuilder(item: DemoItem, index: number): void {
    Row() {
      Text(item.text)
        .fontSize(16)
        .fontColor('#222222');
    }
    .id('row_' + index.toString())
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center);
  }

  build(): void {
    Column() {
      AppBar({
        title: 'Common Components',
        subtitle: 'ohosTest harness',
        showBack: true,
        rightActions: [
          {
            text: 'Toast',
            onAction: (): void => {
              CommonToast.showShort('toast-ok');
            },
          } as AppBarAction,
        ],
      })
        .id('appbar_root');

      Row() {
        Button('Loading')
          .id('btn_loading')
          .onClick((): void => {
            LoadingModal.show('loading-ok');
            setTimeout((): void => {
              LoadingModal.hide();
            }, 800);
          });
        Button('Confirm')
          .id('btn_confirm')
          .margin({ left: 8 })
          .onClick((): void => {
            CommonModal.confirm({
              title: 'Tip',
              message: 'confirm-msg',
            }, (): void => {
              CommonToast.showShort('confirmed');
            });
          });
        Button('Options')
          .id('btn_options')
          .margin({ left: 8 })
          .onClick((): void => {
            const items: CommonOptionItem[] = [
              { itemName: 'OptionA' },
              { itemName: 'OptionB' },
            ];
            CommonModal.options({ title: 'Pick', items: items }, (_idx: number, item: CommonOptionItem): void => {
              CommonToast.showShort(item.itemName);
            });
          });
        Button('Prompt')
          .id('btn_prompt')
          .margin({ left: 8 })
          .onClick((): void => {
            this.promptController.open();
          });
        Button('Refresh')
          .id('btn_refresh_state')
          .margin({ left: 8 })
          .onClick((): void => {
            this.plmController.showRefreshState();
            setTimeout((): void => {
              this.plmController.refreshComplete(true, false);
            }, 600);
          });
      }
      .width('100%')
      .padding(12)
      .id('action_row');

      PullLoadMoreList({
        dataSource: this.data,
        controller: this.plmController,
        renderRow: (item: DemoItem, index: number): void => this.rowBuilder(item, index),
        refresh: (): void => {
          setTimeout((): void => {
            this.plmController.refreshComplete(true, false);
          }, 200);
        },
        loadMore: (): void => {
          setTimeout((): void => {
            this.plmController.loadMoreComplete(false);
          }, 200);
        },
      })
        .id('pull_list')
        .layoutWeight(1);
    }
    .id('common_components_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
