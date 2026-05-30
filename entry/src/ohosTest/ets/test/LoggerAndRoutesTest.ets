import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Logger, LOGGER_RING_CAPACITY, LogEntry } from '../../../main/ets/ai-debug/Logger';
import { HttpRecorder, HTTP_RECORDER_CAPACITY, HttpRecord } from '../../../main/ets/ai-debug/HttpRecorder';
import { NavigationService } from '../../../main/ets/navigation/NavigationService';
import { RouteName, ROUTE_NAMES, isKnownRoute } from '../../../main/ets/navigation/Routes';
import { DebugDumper, DumpPayload, StoreLike } from '../../../main/ets/ai-debug/DebugDumper';
import { EventActionDispatcher } from '../../../main/ets/utils/EventActionDispatcher';
import { DynamicActor, DynamicEvent, DynamicRepo } from '../../../main/ets/store/DynamicStore';

class DemoStorePayload {
  k: number = 1;
}

class DemoStore implements StoreLike {
  toJSON(): Object {
    return new DemoStorePayload();
  }
}

function makeActor(login: string): DynamicActor {
  return {
    id: 1,
    login: login,
    display_login: login,
    avatar_url: '',
  } as DynamicActor;
}

function makeRepo(name: string): DynamicRepo {
  return {
    id: 2,
    name: name,
    url: '',
  } as DynamicRepo;
}

function makeEvent(type: string, repoName: string, payload: Record<string, Object>): DynamicEvent {
  return {
    id: type + '-1',
    type: type,
    actor: makeActor('fork-owner'),
    repo: makeRepo(repoName),
    created_at: '2024-01-01T00:00:00Z',
    payload: payload,
  } as DynamicEvent;
}

export default function LoggerAndRoutesTest(): void {
  describe('LoggerAndRoutesTest', (): void => {

    beforeEach((): void => {
      Logger.clear();
      HttpRecorder.clear();
      NavigationService.clear();
    });

    it('logger_default_capacity_is_500', 0, (): void => {
      expect(LOGGER_RING_CAPACITY).assertEqual(500);
      expect(Logger.getCapacity()).assertEqual(500);
    });

    it('logger_ring_buffer_drops_oldest', 0, (): void => {
      Logger.setCapacity(3);
      Logger.i('t', 'a');
      Logger.i('t', 'b');
      Logger.i('t', 'c');
      Logger.i('t', 'd');
      const snap: LogEntry[] = Logger.snapshot();
      expect(snap.length).assertEqual(3);
      expect(snap[0].msg).assertEqual('b');
      expect(snap[2].msg).assertEqual('d');
      Logger.setCapacity(LOGGER_RING_CAPACITY);
    });

    it('logger_levels_recorded', 0, (): void => {
      Logger.d('tag', 'dm');
      Logger.i('tag', 'im');
      Logger.w('tag', 'wm');
      Logger.e('tag', 'em', new Error('boom'));
      const snap: LogEntry[] = Logger.snapshot();
      expect(snap.length).assertEqual(4);
      expect(snap[0].level).assertEqual('D');
      expect(snap[1].level).assertEqual('I');
      expect(snap[2].level).assertEqual('W');
      expect(snap[3].level).assertEqual('E');
      expect(snap[3].msg.indexOf('boom') >= 0).assertTrue();
    });

    it('logger_snapshot_limit_returns_tail', 0, (): void => {
      for (let i: number = 0; i < 10; i++) {
        Logger.i('t', 'm' + i);
      }
      const tail: LogEntry[] = Logger.snapshot(3);
      expect(tail.length).assertEqual(3);
      expect(tail[0].msg).assertEqual('m7');
      expect(tail[2].msg).assertEqual('m9');
    });

    it('http_recorder_default_capacity_is_30', 0, (): void => {
      expect(HTTP_RECORDER_CAPACITY).assertEqual(30);
      expect(HttpRecorder.getCapacity()).assertEqual(30);
    });

    it('http_recorder_drops_oldest_over_capacity', 0, (): void => {
      for (let i: number = 0; i < 35; i++) {
        HttpRecorder.record({
          url: 'https://api.github.com/test/' + i,
          method: 'GET',
          status: 200,
          ms: i,
        });
      }
      const snap: HttpRecord[] = HttpRecorder.snapshot();
      expect(snap.length).assertEqual(30);
      expect(snap[0].ms).assertEqual(5);
      expect(snap[29].ms).assertEqual(34);
    });

    it('http_recorder_strips_sensitive_query', 0, (): void => {
      HttpRecorder.record({
        url: 'https://api.github.com/u?access_token=abc&page=2',
        method: 'GET',
        status: 200,
        ms: 12,
      });
      const snap: HttpRecord[] = HttpRecorder.snapshot();
      expect(snap.length).assertEqual(1);
      expect(snap[0].url.indexOf('abc') < 0).assertTrue();
      expect(snap[0].url.indexOf('access_token=***') >= 0).assertTrue();
      expect(snap[0].url.indexOf('page=2') >= 0).assertTrue();
    });

    it('routes_enum_contains_required_pages', 0, (): void => {
      expect(RouteName.Welcome).assertEqual('Welcome');
      expect(RouteName.Login).assertEqual('Login');
      expect(RouteName.Home).assertEqual('Home');
      expect(RouteName.Detail).assertEqual('Detail');
      expect(RouteName.Search).assertEqual('Search');
      expect(RouteName.Profile).assertEqual('Profile');
      expect(RouteName.About).assertEqual('About');
      expect(ROUTE_NAMES.length >= 7).assertTrue();
      expect(isKnownRoute('Home')).assertTrue();
      expect(isKnownRoute('NotARoute')).assertFalse();
    });

    it('navigation_service_mirror_push_pop', 0, (): void => {
      NavigationService.push(RouteName.Welcome);
      NavigationService.push(RouteName.Login);
      NavigationService.push(RouteName.Home);
      expect(NavigationService.size()).assertEqual(3);
      const names: string[] = NavigationService.getAllPathName();
      expect(names[0]).assertEqual('Welcome');
      expect(names[2]).assertEqual('Home');
      NavigationService.pop();
      expect(NavigationService.size()).assertEqual(2);
      expect(NavigationService.getAllPathName()[1]).assertEqual('Login');
    });

    it('navigation_service_pop_to_name', 0, (): void => {
      NavigationService.push(RouteName.Welcome);
      NavigationService.push(RouteName.Login);
      NavigationService.push(RouteName.Home);
      NavigationService.push(RouteName.Detail);
      NavigationService.popTo(RouteName.Login);
      const names: string[] = NavigationService.getAllPathName();
      expect(names.length).assertEqual(2);
      expect(names[1]).assertEqual('Login');
    });

    it('navigation_service_replace_top', 0, (): void => {
      NavigationService.push(RouteName.Welcome);
      NavigationService.replace(RouteName.Login);
      const names: string[] = NavigationService.getAllPathName();
      expect(names.length).assertEqual(1);
      expect(names[0]).assertEqual('Login');
    });

    it('debug_dumper_payload_contains_routes_and_logs', 0, (): void => {
      Logger.i('boot', 'hello');
      HttpRecorder.record({
        url: 'https://api.github.com/u',
        method: 'GET',
        status: 200,
        ms: 11,
      });
      NavigationService.push(RouteName.Welcome);
      DebugDumper.registerStore('demoStore', new DemoStore());
      const payload: DumpPayload = DebugDumper.buildPayload();
      expect(payload.routes.length).assertEqual(1);
      expect(payload.routes[0].name).assertEqual('Welcome');
      expect(payload.consoleRecent.length >= 1).assertTrue();
      expect(payload.httpRecent.length).assertEqual(1);
      const demo: Object = payload.stores['demoStore'];
      expect(demo !== undefined).assertTrue();
      DebugDumper.unregisterStore('demoStore');
    });

    it('debug_dumper_format_ts_yyyymmdd_hhmmss', 0, (): void => {
      const fixed: number = new Date(2026, 4, 24, 12, 7, 9).getTime();
      const s: string = DebugDumper.formatTs(fixed);
      expect(s).assertEqual('20260524-120709');
    });

    it('event_dispatcher_fork_event_uses_compose_repo_route', 0, (): void => {
      const payload: Record<string, Object> = {};
      const event: DynamicEvent = makeEvent('ForkEvent', 'octocat/Hello-World', payload);

      EventActionDispatcher.dispatch(event);

      const routes = NavigationService.snapshot();
      expect(routes.length).assertEqual(1);
      expect(routes[0].name).assertEqual(RouteName.RepositoryDetail);
      const param: Record<string, Object> = routes[0].param as Record<string, Object>;
      expect(String(param['fullName'])).assertEqual('octocat/Hello-World');
      expect(String(param['fullName']) !== 'fork-owner/Hello-World').assertTrue();
    });

    it('event_dispatcher_release_event_opens_external_compose_tarball_url', 0, (): void => {
      const release: Record<string, Object> = {
        'tarball_url': 'https://api.github.com/repos/octocat/Hello-World/tarball/v1.0',
        'html_url': 'https://github.com/octocat/Hello-World/releases/tag/v1.0',
      };
      const payload: Record<string, Object> = { 'release': release };
      const event: DynamicEvent = makeEvent('ReleaseEvent', 'octocat/Hello-World', payload);
      let openedUrl: string = '';

      EventActionDispatcher.dispatch(event, '', (url: string): boolean => {
        openedUrl = url;
        return true;
      });

      const routes = NavigationService.snapshot();
      expect(routes.length).assertEqual(0);
      expect(openedUrl).assertEqual('https://api.github.com/repos/octocat/Hello-World/tarball/v1.0');
    });

    it('event_dispatcher_release_event_falls_back_to_web_without_external_handler', 0, (): void => {
      const release: Record<string, Object> = {
        'tarballUrl': 'https://api.github.com/repos/octocat/Hello-World/tarball/v1.0',
      };
      const payload: Record<string, Object> = { 'release': release };
      const event: DynamicEvent = makeEvent('ReleaseEvent', 'octocat/Hello-World', payload);

      EventActionDispatcher.dispatch(event);

      const routes = NavigationService.snapshot();
      expect(routes.length).assertEqual(1);
      expect(routes[0].name).assertEqual(RouteName.WebPage);
      const param: Record<string, Object> = routes[0].param as Record<string, Object>;
      expect(String(param['uri'])).assertEqual('https://api.github.com/repos/octocat/Hello-World/tarball/v1.0');
    });

    it('event_dispatcher_member_event_uses_compose_person_route', 0, (): void => {
      const payload: Record<string, Object> = {};
      const event: DynamicEvent = makeEvent('MemberEvent', 'octocat/Hello-World', payload);

      EventActionDispatcher.dispatch(event);

      const routes = NavigationService.snapshot();
      expect(routes.length).assertEqual(1);
      expect(routes[0].name).assertEqual(RouteName.UserDetail);
      const param: Record<string, Object> = routes[0].param as Record<string, Object>;
      expect(String(param['login'])).assertEqual('fork-owner');
    });

  });
}
