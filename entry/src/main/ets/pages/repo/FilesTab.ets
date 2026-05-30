import { I18n } from '../../i18n/I18n';
import { PullLoadMoreList, PullLoadMoreController } from '../../common/PullLoadMoreList';
import { RepositoryFileItem } from '../../store/RepositoryDetailStore';
import { IconFont, FA_FOLDER, FA_CODE } from '../../common/IconFont';
import { GSYSpacing, GSYColor, GSYFontSize } from '../../style/Theme';

interface BreadcrumbItem {
  label: string;
  path: string;
  index: number;
}

export function isImageOrArchiveFile(fileName: string): boolean {
  if (fileName === null || fileName === undefined) {
    return false;
  }
  const lower: string = fileName.toLowerCase();
  const ext: string = lower.lastIndexOf('.') >= 0 ? lower.substring(lower.lastIndexOf('.') + 1) : lower;
  return ext === 'png' || ext === 'jpg' || ext === 'jpeg' || ext === 'gif'
    || ext === 'bmp' || ext === 'webp' || ext === 'zip' || ext === 'rar'
    || ext === '7z' || ext === 'tar' || ext === 'gz';
}

@Component
export struct FilesTab {
  @Prop files: RepositoryFileItem[] = [];
  @Prop currentPath: string = '';
  @Prop fullName: string = '';
  @Prop branch: string = '';
  @Link controller: PullLoadMoreController;
  refresh: () => void = (): void => {};
  onFileClick: (item: RepositoryFileItem) => void = (_item: RepositoryFileItem): void => {};
  onBack: () => void = (): void => {};
  onPathChange: (path: string) => void = (_path: string): void => {};

  private buildCrumbs(): BreadcrumbItem[] {
    const list: BreadcrumbItem[] = [];
    list.push({ label: '.', path: '', index: 0 });
    if (this.currentPath.length === 0) {
      return list;
    }
    const segs: string[] = this.currentPath.split('/');
    let acc: string = '';
    for (let i: number = 0; i < segs.length; i++) {
      const seg: string = segs[i];
      if (seg.length === 0) {
        continue;
      }
      acc = acc.length > 0 ? acc + '/' + seg : seg;
      list.push({ label: seg, path: acc, index: i + 1 });
    }
    return list;
  }

  private handleRowTap(item: RepositoryFileItem): void {
    if (item.type === 'dir') {
      this.onPathChange(item.path);
      this.onFileClick(item);
      return;
    }
    if (isImageOrArchiveFile(item.name)) {
      return;
    }
    // 文件类型一律交给 RepositoryDetailPage.openFile 处理路由（fullName/branch 在父页面才有 context），
    // 不在这里直接 NavigationService.push。
    this.onFileClick(item);
  }

  private handleCrumbTap(crumb: BreadcrumbItem): void {
    if (crumb.path === this.currentPath) {
      return;
    }
    this.onPathChange(crumb.path);
  }

  @Builder
  rowBuilder(item: RepositoryFileItem, index: number): void {
    Row() {
      IconFont({
        char: item.type === 'dir' ? FA_FOLDER : FA_CODE,
        glyphSize: 16,
        glyphColor: item.type === 'dir' ? GSYColor.actionBlue : GSYColor.subText,
      })
        .id('repo_file_row_icon_' + index.toString());

      Text(item.name)
        .id('repo_file_row_name_' + index.toString())
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.primary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: 12 });
    }
    .id('repo_file_row_' + index.toString())
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.handleRowTap(item);
    });
  }

  @Builder
  emptyBuilder(): void {
    Column() {
      Text(I18n('reposFile'))
        .id('repo_file_empty_title')
        .fontSize(15) // TODO: 字号 15 暂无 token 映射
        .fontColor(GSYColor.subText);
      Text(I18n('userInfoNoting'))
        .id('repo_file_empty_desc')
        .fontSize(GSYFontSize.small)
        .fontColor(GSYColor.tabUnSelect)
        .margin({ top: 8 });
    }
    .id('repo_file_empty_root')
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  breadcrumbBuilder(): void {
    Row() {
      ForEach(this.buildCrumbs(), (crumb: BreadcrumbItem): void => {
        Text(crumb.label)
          .id('repo_file_breadcrumb_seg_' + crumb.index.toString())
          .fontSize(GSYFontSize.small)
          .fontColor(crumb.path === this.currentPath ? GSYColor.primary : GSYColor.actionBlue)
          .fontWeight(crumb.path === this.currentPath ? FontWeight.Bold : FontWeight.Normal)
          .onClick((): void => {
            this.handleCrumbTap(crumb);
          });
        Text('>')
          .id('repo_file_breadcrumb_sep_' + crumb.index.toString())
          .fontSize(GSYFontSize.small)
          .fontColor(GSYColor.tabUnSelect)
          .margin({ left: 4, right: 4 });
      }, (crumb: BreadcrumbItem): string => crumb.index.toString() + '_' + crumb.path);
    }
    .id('repo_file_breadcrumb')
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(GSYColor.surfaceSubtle)
    .alignItems(VerticalAlign.Center);
  }

  build(): void {
    Column() {
      this.breadcrumbBuilder();
      PullLoadMoreList({
        dataSource: this.files,
        controller: this.controller,
        renderRow: (item: Object, index: number): void => this.rowBuilder(item as RepositoryFileItem, index),
        renderEmpty: (): void => this.emptyBuilder(),
        refresh: (): void => {
          this.refresh();
        },
        loadMore: (): void => {
        },
        tailPadding: GSYSpacing.normalEdge * 5,
      })
        .id('repo_file_list')
        .layoutWeight(1);
    }
    .id('repo_file_root')
    .width('100%')
    .height('100%')
    .backgroundColor(GSYColor.white);
  }
}
