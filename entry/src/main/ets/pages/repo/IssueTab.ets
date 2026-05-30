import { I18n } from '../../i18n/I18n';
import type { TranslationMap } from '../../i18n/I18n';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { NavigationService } from '../../navigation/NavigationService';
import { RouteName } from '../../navigation/Routes';
import { GSYSpacing, GSYColor, GSYFontSize, GSYShadow } from '../../style/Theme';
import { IconFont, FA_PLUS, FA_SEARCH, FA_TIMES, FA_BUG } from '../../common/IconFont';
import {
  RepositoryIssueItem,
  ISSUE_STATE_OPEN,
  ISSUE_STATE_CLOSED,
  ISSUE_STATE_ALL
} from '../../store/RepositoryDetailStore';

const ISSUE_SEARCH_HEADER_HEIGHT: number = 56;
const ISSUE_SEARCH_INPUT_HEIGHT: number = 52;
const ISSUE_SEARCH_ICON_SIZE: number = 22;

interface IssueChipModel {
  key: string;
  label: keyof TranslationMap;
  id: string;
}

@Component
export struct IssueTab {
  @Prop issues: RepositoryIssueItem[] = [];
  @Prop fullName: string = '';
  @Prop currentState: string = ISSUE_STATE_ALL;
  @Prop searchQuery: string = '';
  @Prop showCreateFab: boolean = true;
  @Link controller: PullLoadMoreController;
  refresh: () => void = (): void => {};
  loadMore: () => void = (): void => {};
  onIssueClick: (item: RepositoryIssueItem) => void = (_item: RepositoryIssueItem): void => {};
  onStateChange: (state: string) => void = (_state: string): void => {};
  onSearchQueryChange: (query: string) => void = (_query: string): void => {};
  onSearch: () => void = (): void => {};
  onCreateIssue: () => void = (): void => {};

  private chipDefs: IssueChipModel[] = [
    { key: ISSUE_STATE_ALL, label: 'issueAllText', id: 'repo_issue_chip_all' },
    { key: ISSUE_STATE_OPEN, label: 'issueOpenText', id: 'repo_issue_chip_open' },
    { key: ISSUE_STATE_CLOSED, label: 'issueCloseText', id: 'repo_issue_chip_closed' },
  ];

  private handleChipTap(state: string): void {
    if (state === this.currentState) {
      return;
    }
    this.onStateChange(state);
  }

  private hasSearchQuery(): boolean {
    return this.searchQuery !== null && this.searchQuery !== undefined && this.searchQuery.trim().length > 0;
  }

  private submitSearch(): void {
    this.onSearch();
  }

  private clearSearch(): void {
    if (!this.hasSearchQuery()) {
      return;
    }
    this.onSearchQueryChange('');
    this.onSearch();
  }

  private handleRowTap(item: RepositoryIssueItem): void {
    this.onIssueClick(item);
    if (this.fullName.length > 0) {
      const param: Record<string, Object> = {
        'fullName': this.fullName,
        'number': item.number,
      };
      NavigationService.push(RouteName.IssueDetail, param);
    }
  }

  private issueTitle(item: RepositoryIssueItem): string {
    return '#' + item.number.toString() + ' ' + item.title;
  }

  private issueDate(item: RepositoryIssueItem): string {
    const raw: string = item.created_at !== null && item.created_at !== undefined ? item.created_at : '';
    const idx: number = raw.indexOf('T');
    return idx >= 0 ? raw.substring(0, idx) : raw;
  }

  private issueOpenedBy(item: RepositoryIssueItem): string {
    const user: string = item.user !== null && item.user !== undefined && item.user.login.length > 0
      ? item.user.login : I18n('unknown');
    return I18n('issueOpenedBy', { 'user': user });
  }

  @Builder
  searchHeaderBuilder(): void {
    Row() {
      TextInput({ text: this.searchQuery, placeholder: I18n('searchIssue') })
        .id('repo_issue_search_input')
        .layoutWeight(1)
        .height(ISSUE_SEARCH_INPUT_HEIGHT)
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .placeholderColor(GSYColor.subText)
        .placeholderFont({ size: GSYFontSize.small })
        .caretColor(GSYColor.primary)
        .defaultFocus(false)
        .backgroundColor(GSYColor.white)
        .borderRadius(3)
        .padding({
          left: GSYSpacing.halfEdge,
          right: GSYSpacing.halfEdge,
        })
        .margin({
          left: GSYSpacing.halfEdge,
          right: GSYSpacing.halfEdge,
        })
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string): void => {
          this.onSearchQueryChange(value);
        })
        .onSubmit((): void => {
          this.submitSearch();
        });

      Column() {
        IconFont({
          char: this.hasSearchQuery() ? FA_TIMES : FA_SEARCH,
          glyphSize: ISSUE_SEARCH_ICON_SIZE,
          glyphColor: GSYColor.mainText,
        })
          .id(this.hasSearchQuery() ? 'repo_issue_search_clear_icon' : 'repo_issue_search_icon');
      }
      .id('repo_issue_search_submit_btn')
      .width(44)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick((): void => {
        if (this.hasSearchQuery()) {
          this.clearSearch();
          return;
        }
        this.submitSearch();
      });
    }
    .id('repo_issue_search_row')
    .width('auto')
    .height(ISSUE_SEARCH_HEADER_HEIGHT)
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .backgroundColor(GSYColor.white)
    .border({
      width: 0.5,
      color: GSYColor.line,
      radius: 3,
    })
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  chipBuilder(chip: IssueChipModel): void {
    Row() {
      if (this.currentState === chip.key) {
        IconFont({
          char: '\uf00c',
          glyphSize: 12,
          glyphColor: GSYColor.miWhite,
        })
          .margin({ right: 4 });
      }
      Text(I18n(chip.label))
        .id(chip.id)
        .fontSize(GSYFontSize.small)
        .fontColor(this.currentState === chip.key ? GSYColor.miWhite : GSYColor.subText);
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.handleChipTap(chip.key);
    });
  }

  @Builder
  chipBarBuilder(): void {
    Row() {
      this.chipBuilder(this.chipDefs[0]);
      Divider().vertical(true).strokeWidth(0.5).color(GSYColor.line).height(16);
      this.chipBuilder(this.chipDefs[1]);
      Divider().vertical(true).strokeWidth(0.5).color(GSYColor.line).height(16);
      this.chipBuilder(this.chipDefs[2]);
    }
    .id('repo_issue_chip_bar')
    .width('auto')
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.normalEdge,
    })
    .backgroundColor(GSYColor.primary)
    .borderRadius(4)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  rowBuilder(item: RepositoryIssueItem, index: number): void {
    Column() {
      Row() {
        IconFont({
          char: FA_BUG,
          glyphSize: 24,
          glyphColor: GSYColor.mainText,
        })
          .id('repo_issue_row_icon_' + index.toString())
          .margin({ right: 8 });

        Text(this.issueTitle(item))
          .id('repo_issue_row_title_' + index.toString())
          .fontSize(GSYFontSize.normal)
          .fontWeight(FontWeight.Bold)
          .fontColor(GSYColor.mainText)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Text(item.body)
        .id('repo_issue_row_body_' + index.toString())
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.subText)
        .margin({ top: 4 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Row() {
        Text(this.issueOpenedBy(item))
          .id('repo_issue_row_opened_by_' + index.toString())
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subText)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(this.issueDate(item))
          .id('repo_issue_row_date_' + index.toString())
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.subText);
      }
      .width('100%')
      .margin({ top: 4 })
      .alignItems(VerticalAlign.Center);
    }
    .id('repo_issue_row_' + index.toString())
    .width('auto')
    .margin({
      left: GSYSpacing.normalEdge,
      right: GSYSpacing.normalEdge,
      top: GSYSpacing.halfEdge,
      bottom: GSYSpacing.halfEdge,
    })
    .padding(GSYSpacing.normalEdge)
    .borderRadius(3)
    .backgroundColor(GSYColor.white)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: 1,
    })
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => {
      this.handleRowTap(item);
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('reposIssue'))
        .id('repo_issue_empty_title')
        .fontSize(GSYFontSize.middleNormal)
        .fontColor(GSYColor.subText);
      Text(I18n('userInfoNoting'))
        .id('repo_issue_empty_desc')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.tabUnSelect)
        .margin({ top: 8 });
    }
    .id('repo_issue_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  fabBuilder(): void {
    Row() {
      IconFont({
        char: FA_PLUS,
        glyphSize: 24,
        glyphColor: GSYColor.miWhite,
      });
    }
    .id('repo_issue_create_fab')
    .width(48)
    .height(48)
    .borderRadius(24)
    .backgroundColor(GSYColor.primary)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow({
      radius: GSYShadow.radius,
      color: GSYShadow.cardShadowAlpha,
      offsetX: 0,
      offsetY: 2,
    })
    .onClick((): void => {
      this.onCreateIssue();
    });
  }

  build(): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Text('')
          .id('repo_issue_initial_focus_sink')
          .width(1)
          .height(1)
          .opacity(0)
          .focusable(true)
          .defaultFocus(true);
        this.searchHeaderBuilder();
        this.chipBarBuilder();
        PullLoadMoreList({
          dataSource: this.issues,
          controller: this.controller,
          renderRow: (item: Object, index: number): void => this.rowBuilder(item as RepositoryIssueItem, index),
          renderEmpty: (): void => this.emptyBuilder(),
          refresh: (): void => {
            this.refresh();
          },
          loadMore: (): void => {
            this.loadMore();
          },
          tailPadding: GSYSpacing.normalEdge * 5,
        })
          .id('repo_issue_list')
          .layoutWeight(1);
      }
      .id('repo_issue_root')
      .width('100%')
      .height('100%')
      .backgroundColor(GSYColor.white);

      if (this.showCreateFab) {
        this.fabBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: GSYSpacing.normalEdge * 2 });
  }
}
