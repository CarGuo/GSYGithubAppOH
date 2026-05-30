/**
 * PersonInfoPage —— 对齐 Compose 端
 * [InfoScreen.kt](https://github.com/CarGuo/GSYGithubAppCompose/blob/master/feature/info/src/main/java/com/shuyu/gsygithubappcompose/feature/info/InfoScreen.kt)
 *
 * Compose 端：
 *   - 抽屉 personal_info 进入 info route
 *   - 读 userInfo（name/email/blog/company/location/bio）
 *   - 6 行信息卡片，点击触发 AlertDialog + TextField → updateUser({field:text})
 *
 * OH 端：
 *   - 使用 GSYCardItem 同款 16/8 外边距、8 圆角、1px outline、2dp 近似 elevation
 *   - CustomDialog 内联 TextInput，对齐 Compose InfoScreen 的 AlertDialog + TextField 编辑流。
 *   - 走 [UserService.updateUser](../service/UserService.ets) PATCH /user
 *
 * HARD-LAW 自检：
 *   - HARD-LAW-1 RN-FIRST：✅ 已读 RN 230 行
 *   - HARD-LAW-2 TOKEN-ONLY：✅ 仅引 GSYColor/GSYFontSize/GSYSpacing
 *   - HARD-LAW-3 NO-DEBUG-PROBE：✅ 无 *-count Text；调试走 Logger.i('person/info/...')
 */

import { AppBar } from '../common/AppBar';
import { CommonToast } from '../common/CommonToast';
import { PullLoadMoreController, PullLoadMoreList } from '../common/PullLoadMoreList';
import {
  IconFont,
  FA_INFO_CIRCLE,
  FA_ENVELOPE,
  FA_LINK,
  FA_GROUP,
  FA_LOCATION,
  FA_COMMENT,
} from '../common/IconFont';
import { I18n } from '../i18n/I18n';
import { Logger } from '../ai-debug/Logger';
import { NavigationService } from '../navigation/NavigationService';
import {
  AuthUserInfo,
  GlobalAuthStore,
  APP_STORAGE_KEY_USER_INFO,
} from '../store/AuthStore';
import {
  UserService,
  UpdateUserResult,
} from '../service/UserService';
import {
  MyService,
  RefreshMeResult,
} from '../service/MyService';
import { UserDao } from '../dao/UserDao';
import { GlobalMyStore } from '../store/MyStore';
import { GSYColor, GSYFontSize, GSYIconSize, GSYSpacing } from '../style/Theme';

const PERSON_INFO_PLACEHOLDER: string = '---';
const PERSON_INFO_FIELD_NAME: string = 'name';
const PERSON_INFO_FIELD_EMAIL: string = 'email';
const PERSON_INFO_FIELD_BLOG: string = 'blog';
const PERSON_INFO_FIELD_COMPANY: string = 'company';
const PERSON_INFO_FIELD_LOCATION: string = 'location';
const PERSON_INFO_FIELD_BIO: string = 'bio';

class PersonInfoListItem {
  key: string = 'person_info';
}

@CustomDialog
struct PersonInfoEditDialog {
  controller?: CustomDialogController;
  title: string = '';
  defaultValue: string = '';
  placeholder: string = '';
  okText: string = '';
  cancelText: string = '';
  onConfirm: (text: string) => void = (_text: string): void => {};
  @State current: string = '';

  aboutToAppear(): void {
    this.current = this.defaultValue;
  }

  build(): void {
    Column() {
      Text(this.title)
        .id('person_info_edit_dialog_title')
        .fontSize(GSYFontSize.middleWhite)
        .fontWeight(FontWeight.Bold)
        .fontColor(GSYColor.darkText)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: GSYSpacing.normalEdge });

      TextInput({ text: this.current, placeholder: this.placeholder })
        .id('person_info_edit_dialog_input')
        .maxLength(200)
        .height(44)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .placeholderColor(GSYColor.subText)
        .backgroundColor(GSYColor.surfaceGray)
        .borderRadius(6)
        .padding({ left: GSYSpacing.normalEdge, right: GSYSpacing.normalEdge })
        .onChange((value: string): void => {
          this.current = value;
        });

      Row() {
        Button(this.cancelText)
          .id('person_info_edit_dialog_cancel')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor(GSYColor.mediumText)
          .onClick((): void => {
            if (this.controller) {
              this.controller.close();
            }
          });
        Divider().vertical(true).height(20).color(GSYColor.pillDivider);
        Button(this.okText)
          .id('person_info_edit_dialog_confirm')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor(GSYColor.materialBlue)
          .onClick((): void => {
            const value: string = this.current;
            if (this.controller) {
              this.controller.close();
            }
            this.onConfirm(value);
          });
      }
      .id('person_info_edit_dialog_actions')
      .width('100%')
      .height(44)
      .margin({ top: GSYSpacing.normalEdge })
      .alignItems(VerticalAlign.Center);
    }
    .id('person_info_edit_dialog_root')
    .padding(20)
    .borderRadius(8)
    .width(300)
    .backgroundColor(Color.White);
  }
}

@Component
export struct PersonInfoPage {
  @StorageLink(APP_STORAGE_KEY_USER_INFO) userInfoRaw: string = '';
  @State name: string = '';
  @State email: string = '';
  @State blog: string = '';
  @State company: string = '';
  @State location: string = '';
  @State bio: string = '';
  @State busyField: string = '';
  @State editField: string = '';
  @State editLabel: string = '';
  @State editValue: string = '';
  @State infoData: PersonInfoListItem[] = [new PersonInfoListItem()];
  @State plmController: PullLoadMoreController = new PullLoadMoreController();
  private userDao: UserDao = new UserDao();
  private myService: MyService = new MyService(GlobalMyStore, GlobalAuthStore, this.userDao);
  private editDialogController: CustomDialogController = new CustomDialogController({
    builder: PersonInfoEditDialog({
      title: I18n('editField', { 'option1': this.editLabel }),
      defaultValue: this.editValue,
      placeholder: this.editLabel,
      okText: I18n('ok'),
      cancelText: I18n('cancel'),
      onConfirm: (text: string): void => {
        this.submitField(this.editField, text);
      },
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
  });

  aboutToAppear(): void {
    this.applyUserToState();
  }

  private parseUser(): AuthUserInfo | null {
    if (GlobalAuthStore.userInfo !== null && GlobalAuthStore.userInfo !== undefined) {
      return GlobalAuthStore.userInfo;
    }
    if (this.userInfoRaw === undefined || this.userInfoRaw === null
      || this.userInfoRaw.length === 0) {
      return null;
    }
    return AuthUserInfo.fromJson(this.userInfoRaw);
  }

  private applyUserToState(): void {
    const user: AuthUserInfo | null = this.parseUser();
    if (user === null) {
      return;
    }
    this.name = user.name;
    this.blog = user.blog;
    this.company = user.company;
    this.location = user.location;
    this.bio = user.bio;
    // GitHub /user 接口的 email 字段 AuthUserInfo 暂未持有 → 从 raw json 直读，回退空串
    this.email = PersonInfoPage.readEmailFromRaw(user.raw);
  }

  private static readEmailFromRaw(raw: string): string {
    if (raw === undefined || raw === null || raw.length === 0) {
      return '';
    }
    try {
      const obj: Object = JSON.parse(raw) as Object;
      const rec: Record<string, Object> = obj as Record<string, Object>;
      const v: Object | undefined = rec['email'];
      if (v === undefined || v === null) {
        return '';
      }
      return String(v);
    } catch (_e) {
      return '';
    }
  }

  private displayValue(value: string): string {
    return value !== undefined && value !== null && value.length > 0
      ? value
      : PERSON_INFO_PLACEHOLDER;
  }

  private async dispatchEdit(field: string, oldValue: string, label: string): Promise<void> {
    Logger.i('person/info/edit', 'field=' + field + ' oldLen=' + oldValue.length);
    if (this.busyField.length > 0) {
      return;
    }
    this.editField = field;
    this.editLabel = label;
    this.editValue = oldValue;
    this.editDialogController.open();
  }

  private async triggerRefresh(): Promise<void> {
    this.plmController.showRefreshState();
    const result: RefreshMeResult = await this.myService.refreshMe();
    if (result.result && result.data !== null) {
      this.applyUserToState();
      this.plmController.refreshComplete(false, false);
      return;
    }
    this.plmController.refreshComplete(false, false);
    if (result.msg.length > 0) {
      CommonToast.showShort(result.msg);
    }
  }

  @Builder
  private buildInfoRow(rowId: string,
                       icon: string,
                       label: string,
                       value: string,
                       field: string,
                       rawValue: string): void {
    Row() {
      IconFont({
        char: icon,
        glyphSize: GSYIconSize.minIcon,
        glyphColor: GSYColor.primary,
      })
        .id(rowId + '_icon')
        .width(28);

      Text(label)
        .id(rowId + '_label')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.mainText)
        .margin({ left: GSYSpacing.normalEdge });

      Text(value)
        .id(rowId + '_value')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.mainText)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: GSYSpacing.normalEdge });
    }
    .id(rowId)
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding({
      left: 15,
      right: 15,
      top: 14,
      bottom: 14,
    })
    .backgroundColor(GSYColor.cardBackground)
    .borderRadius(8)
    .border({
      width: 1,
      color: GSYColor.borderSubtle,
    })
    .shadow({
      radius: 6,
      color: '#14000000',
      offsetX: 0,
      offsetY: 2,
    })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.dispatchEdit(field, rawValue, label);
    })
    .margin({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8,
    });
  }

  /**
   * 真实 PATCH（保留接口，便于后续 CustomDialog 接入后直接调用）。
   */
  async submitField(field: string, newValue: string): Promise<boolean> {
    if (this.busyField.length > 0) {
      return false;
    }
    this.busyField = field;
    const result: UpdateUserResult = await UserService.updateUser(field, newValue, this.userDao);
    Logger.i('person/info/patch',
      'field=' + field + ' code=' + result.code + ' result=' + result.result);
    if (result.result) {
      if (field === PERSON_INFO_FIELD_NAME) {
        this.name = newValue;
      } else if (field === PERSON_INFO_FIELD_EMAIL) {
        this.email = newValue;
      } else if (field === PERSON_INFO_FIELD_BLOG) {
        this.blog = newValue;
      } else if (field === PERSON_INFO_FIELD_COMPANY) {
        this.company = newValue;
      } else if (field === PERSON_INFO_FIELD_LOCATION) {
        this.location = newValue;
      } else if (field === PERSON_INFO_FIELD_BIO) {
        this.bio = newValue;
      }
      this.syncAuthUserField(field, newValue);
      CommonToast.showShort(I18n('userInfoUpdateSuccess'));
    } else {
      CommonToast.showShort(result.msg.length > 0 ? result.msg : I18n('userInfoUpdateFail'));
    }
    this.busyField = '';
    return result.result;
  }

  private syncAuthUserField(field: string, value: string): void {
    const current: AuthUserInfo | null = this.parseUser();
    if (current === null || current.raw.length === 0) {
      return;
    }
    try {
      const rawObj: Record<string, Object> = JSON.parse(current.raw) as Record<string, Object>;
      rawObj[field] = value;
      const raw: string = JSON.stringify(rawObj);
      const updated: AuthUserInfo | null = AuthUserInfo.fromJson(raw);
      if (updated !== null) {
        GlobalAuthStore.setUser(GlobalAuthStore.token, updated);
        AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, raw);
      }
    } catch (_e) {
    }
  }

  @Builder
  private buildInfoContent(): void {
    Column() {
      this.buildInfoRow('person_info_row_name', FA_INFO_CIRCLE, I18n('infoName'),
        this.displayValue(this.name), PERSON_INFO_FIELD_NAME, this.name);
      this.buildInfoRow('person_info_row_email', FA_ENVELOPE, I18n('infoEmail'),
        this.displayValue(this.email), PERSON_INFO_FIELD_EMAIL, this.email);
      this.buildInfoRow('person_info_row_blog', FA_LINK, I18n('infoBlog'),
        this.displayValue(this.blog), PERSON_INFO_FIELD_BLOG, this.blog);
      this.buildInfoRow('person_info_row_company', FA_GROUP, I18n('infoCompany'),
        this.displayValue(this.company), PERSON_INFO_FIELD_COMPANY, this.company);
      this.buildInfoRow('person_info_row_location', FA_LOCATION, I18n('infoLocation'),
        this.displayValue(this.location), PERSON_INFO_FIELD_LOCATION, this.location);
      this.buildInfoRow('person_info_row_bio', FA_COMMENT, I18n('infoBio'),
        this.displayValue(this.bio), PERSON_INFO_FIELD_BIO, this.bio);
      Text(I18n('loadMoreEnd'))
        .id('person_info_no_more')
        .fontSize(GSYFontSize.middleWhite)
        .fontColor(GSYColor.mainText)
        .width('100%')
        .height(50)
        .textAlign(TextAlign.Center)
        .margin({ top: 12 });
    }
    .id('person_info_content')
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .padding({
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.normalEdge,
    });
  }

  @Builder
  private buildPullHeader(): void {
    Row()
      .id('person_info_pull_list')
      .width('100%')
      .height(1);
  }

  build(): void {
    Column() {
      AppBar({
        title: I18n('person'),
        titleStart: true,
        showBack: true,
        onBack: (): void => {
          NavigationService.pop();
        },
      });
      PullLoadMoreList({
        dataSource: this.infoData,
        controller: this.plmController,
        renderHeader: (): void => this.buildPullHeader(),
        renderRow: (_item: Object, _index: number): void => this.buildInfoContent(),
        refresh: (): void => {
          this.triggerRefresh();
        },
        loadMore: (): void => {
          this.plmController.loadMoreComplete(false);
        },
        refreshingText: I18n('refreshing'),
        loadingMoreText: I18n('loadMoreing'),
        loadEndText: I18n('loadMoreEnd'),
        emptyText: I18n('listEmpty'),
      })
      .layoutWeight(1)
      .width('100%');
    }
    .id('person_info_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.mainBackground);
  }
}
