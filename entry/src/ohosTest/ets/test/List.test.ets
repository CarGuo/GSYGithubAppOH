import I18nTest from './I18nTest';
import HttpManagerTest from './HttpManagerTest';
import RdbAndEventBusTest from './RdbAndEventBusTest';
import LoggerAndRoutesTest from './LoggerAndRoutesTest';
import CommonComponentsTest from './CommonComponentsTest';
import HomeUiTest from './HomeUiTest';
import UtilsTest from './UtilsTest';
import DynamicServiceTest from './DynamicServiceTest';
import DynamicUiTest from './DynamicUiTest';
import AuthStoreTest from './AuthStoreTest';
import LoginUiTest from './LoginUiTest';
import TrendServiceTest from './TrendServiceTest';
import TrendUiTest from './TrendUiTest';
import RecommendServiceTest from './RecommendServiceTest';
import MyServiceTest from './MyServiceTest';
import MyUiTest from './MyUiTest';
import RepositoryServiceTest from './RepositoryServiceTest';
import RepositoryDetailUiTest from './RepositoryDetailUiTest';
import RepoTabsServiceTest from './RepoTabsServiceTest';
import RepoTabsUiTest from './RepoTabsUiTest';
import UserServiceTest from './UserServiceTest';
import UserDetailUiTest from './UserDetailUiTest';
import IssueServiceTest from './IssueServiceTest';
import IssueDetailUiTest from './IssueDetailUiTest';
import CommitServiceTest from './CommitServiceTest';
import CodeDetailUiTest from './CodeDetailUiTest';
import PushDetailUiTest from './PushDetailUiTest';
import SearchServiceTest from './SearchServiceTest';
import SearchUiTest from './SearchUiTest';
import NotifyServiceTest from './NotifyServiceTest';
import NotifyUiTest from './NotifyUiTest';
import SubListServiceTest from './SubListServiceTest';
import SubListUiTest from './SubListUiTest';
import SettingUiTest from './SettingUiTest';
import EmojiKeyboardTest from './EmojiKeyboardTest';
import ImagePreviewUiTest from './ImagePreviewUiTest';
import OauthServiceTest from './OauthServiceTest';
import OauthDeepLinkUiTest from './OauthDeepLinkUiTest';
import LoginExpiredFlowTest from './LoginExpiredFlowTest';
import OfflineFallbackTest from './OfflineFallbackTest';
import ContributionServiceTest from './ContributionServiceTest';
import ContributionHeatmapUiTest from './ContributionHeatmapUiTest';
import DrawerHeaderTest from './DrawerHeaderTest';
import DrawerMenuUiTest from './DrawerMenuUiTest';
import ThemeManagerTest from './ThemeManagerTest';
import ThemeUiTest from './ThemeUiTest';
import DaoTest from './DaoTest';
import ReadHistoryServiceTest from './ReadHistoryServiceTest';
import ReadHistoryUiTest from './ReadHistoryUiTest';
import FullTourUiTest from './FullTourUiTest';
import abilityTest from './Ability.test';
import { LOGIC_ONLY } from './LogicOnlyConfig';

function readLogicOnlyFlag(): boolean {
  return LOGIC_ONLY;
}

export default function testsuite(): void {
  const logicOnly: boolean = readLogicOnlyFlag();

  I18nTest();
  HttpManagerTest();
  RdbAndEventBusTest();
  LoggerAndRoutesTest();
  CommonComponentsTest();
  if (!logicOnly) {
    HomeUiTest();
  }
  UtilsTest();
  DynamicServiceTest();
  if (!logicOnly) {
    DynamicUiTest();
  }
  AuthStoreTest();
  if (!logicOnly) {
    LoginUiTest();
  }
  TrendServiceTest();
  if (!logicOnly) {
    TrendUiTest();
  }
  RecommendServiceTest();
  MyServiceTest();
  if (!logicOnly) {
    MyUiTest();
  }
  RepositoryServiceTest();
  if (!logicOnly) {
    RepositoryDetailUiTest();
  }
  RepoTabsServiceTest();
  if (!logicOnly) {
    RepoTabsUiTest();
  }
  UserServiceTest();
  if (!logicOnly) {
    UserDetailUiTest();
  }
  IssueServiceTest();
  if (!logicOnly) {
    IssueDetailUiTest();
  }
  CommitServiceTest();
  if (!logicOnly) {
    CodeDetailUiTest();
    PushDetailUiTest();
  }
  SearchServiceTest();
  if (!logicOnly) {
    SearchUiTest();
  }
  NotifyServiceTest();
  if (!logicOnly) {
    NotifyUiTest();
  }
  SubListServiceTest();
  if (!logicOnly) {
    SubListUiTest();
    SettingUiTest();
  }
  EmojiKeyboardTest();
  if (!logicOnly) {
    ImagePreviewUiTest();
  }
  OauthServiceTest();
  if (!logicOnly) {
    OauthDeepLinkUiTest();
  }
  LoginExpiredFlowTest();
  OfflineFallbackTest();
  ContributionServiceTest();
  if (!logicOnly) {
    ContributionHeatmapUiTest();
  }
  DrawerHeaderTest();
  if (!logicOnly) {
    DrawerMenuUiTest();
  }
  ThemeManagerTest();
  if (!logicOnly) {
    ThemeUiTest();
  }
  DaoTest();
  ReadHistoryServiceTest();
  if (!logicOnly) {
    ReadHistoryUiTest();
    FullTourUiTest();
  }
  abilityTest();
}
