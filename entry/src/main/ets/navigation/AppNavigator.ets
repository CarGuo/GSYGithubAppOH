/**
 * AppNavigator —— R7 Phase A 单根 Navigation 容器
 *
 * 设计说明（参考 [r7-rebuild-blueprint.md § 1.1](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/r7-rebuild-blueprint.md)）：
 *  - 全应用唯一一个 Navigation + NavPathStack，所有页面以 NavDestination 形式注册。
 *  - stack 在本组件构造时创建，注入到 [NavigationService](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/ets/navigation/NavigationService.ets)
 *    供任意 push/pop/replace 调用，避免 KI-020 悬空栈 crash。
 *  - 路由名映射对齐 RN [AppNavigator.js#L144-L334](https://github.com/CarGuo/GSYGithubApp/blob/master/app/navigation/AppNavigator.js#L144-L334)。
 *
 * 注：每个页面 struct 必须 export，且不再使用 @Entry。
 */
import { NavigationService } from './NavigationService';
import { RouteName } from './Routes';

import { WelcomePage } from '../pages/WelcomePage';
import { LoginPage } from '../pages/LoginPage';
import { LoginWebPage } from '../pages/LoginWebPage';
import { HomePage } from '../pages/HomePage';
import { SearchPage } from '../pages/SearchPage';
import { SettingPage } from '../pages/SettingPage';
import { AboutPage } from '../pages/AboutPage';
import { CustomPage } from '../pages/CustomPage';
import { HonorPage } from '../pages/HonorPage';
import { NotifyPage } from '../pages/NotifyPage';
import { ReadHistoryPage } from '../pages/ReadHistoryPage';
import { UserDetailPage } from '../pages/UserDetailPage';
import { RepositoryDetailPage } from '../pages/RepositoryDetailPage';
import { IssueDetailPage } from '../pages/IssueDetailPage';
import { CodeDetailPage } from '../pages/CodeDetailPage';
import { PushDetailPage } from '../pages/PushDetailPage';
import { UserFollowedPage } from '../pages/UserFollowedPage';
import { UserFollowerPage } from '../pages/UserFollowerPage';
import { RepositoryStarPage } from '../pages/RepositoryStarPage';
import { RepositoryWatcherPage } from '../pages/RepositoryWatcherPage';
import { RepositoryForkPage } from '../pages/RepositoryForkPage';
import { PersonInfoPage } from '../pages/PersonInfoPage';
import { ReleasePage } from '../pages/ReleasePage';
import { PhotoPage } from '../pages/PhotoPage';
import { WebPage } from '../pages/WebPage';
import { CommonListPage } from '../pages/CommonListPage';

@Component
export struct AppNavigator {
  private stack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    NavigationService.setStack(this.stack);
  }

  @Builder
  routerMap(name: string, _param: Object): void {
    NavDestination() {
      if (name === RouteName.Welcome) {
        WelcomePage();
      } else if (name === RouteName.Login) {
        LoginPage();
      } else if (name === RouteName.LoginWeb) {
        LoginWebPage();
      } else if (name === RouteName.Home) {
        HomePage();
      } else if (name === RouteName.Search) {
        SearchPage();
      } else if (name === RouteName.Setting) {
        SettingPage();
      } else if (name === RouteName.About) {
        AboutPage();
      } else if (name === RouteName.Custom) {
        CustomPage();
      } else if (name === RouteName.Honor) {
        HonorPage();
      } else if (name === RouteName.Notify) {
        NotifyPage();
      } else if (name === RouteName.ReadHistory) {
        ReadHistoryPage();
      } else if (name === RouteName.UserDetail) {
        UserDetailPage();
      } else if (name === RouteName.RepositoryDetail) {
        RepositoryDetailPage();
      } else if (name === RouteName.IssueDetail) {
        IssueDetailPage();
      } else if (name === RouteName.CodeDetail) {
        CodeDetailPage();
      } else if (name === RouteName.PushDetail) {
        PushDetailPage();
      } else if (name === RouteName.UserFollowed) {
        UserFollowedPage();
      } else if (name === RouteName.UserFollower) {
        UserFollowerPage();
      } else if (name === RouteName.RepositoryStar) {
        RepositoryStarPage();
      } else if (name === RouteName.RepositoryWatcher) {
        RepositoryWatcherPage();
      } else if (name === RouteName.RepositoryFork) {
        RepositoryForkPage();
      } else if (name === RouteName.PersonInfo) {
        PersonInfoPage();
      } else if (name === RouteName.Release) {
        ReleasePage();
      } else if (name === RouteName.Photo) {
        PhotoPage();
      } else if (name === RouteName.WebPage) {
        WebPage();
      } else if (name === RouteName.CommonList) {
        CommonListPage({ initialParam: _param });
      }
    }
    .hideTitleBar(true);
  }

  build(): void {
    Navigation(this.stack) {
      WelcomePage();
    }
    .id('app_navigator_root')
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.routerMap);
  }
}
