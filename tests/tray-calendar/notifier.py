"""A real StatusNotifierItem and DBusMenu; actions only append to a test log."""
import asyncio
import json
import sys
from dbus_next import Variant
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property, signal
from dbus_next.constants import PropertyAccess


def log(action):
    with open(sys.argv[1], 'a') as output:
        output.write(json.dumps(action) + '\n')


class Menu(ServiceInterface):
    def __init__(self): super().__init__('com.canonical.dbusmenu')
    @dbus_property(access=PropertyAccess.READ)
    def Version(self) -> 'u': return 4
    @dbus_property(access=PropertyAccess.READ)
    def TextDirection(self) -> 's': return 'ltr'
    @dbus_property(access=PropertyAccess.READ)
    def Status(self) -> 's': return 'normal'
    @dbus_property(access=PropertyAccess.READ)
    def IconThemePath(self) -> 'as': return []
    @method()
    def GetLayout(self, parent: 'i', depth: 'i', names: 'as') -> 'u(ia{sv}av)':
        child = Variant('(ia{sv}av)', [1, {'label': Variant('s', 'Fixture action'), 'enabled': Variant('b', True)}, []])
        return [1, [0, {}, [child]]]
    @method()
    def GetGroupProperties(self, ids: 'ai', names: 'as') -> 'a(ia{sv})': return []
    @method()
    def AboutToShow(self, entry: 'i') -> 'b': return False
    @method()
    def AboutToShowGroup(self, ids: 'ai') -> 'aiai': return [[], []]
    @method()
    def Event(self, entry: 'i', event: 's', data: 'v', timestamp: 'u'):
        log(['menu', entry, event])
    @method()
    def EventGroup(self, events: 'a(isvu)') -> 'ai': return []
    @method()
    def GetProperty(self, entry: 'i', name: 's') -> 'v': return Variant('s', '')


class Notifier(ServiceInterface):
    def __init__(self):
        super().__init__('org.kde.StatusNotifierItem')
        self.state = 'Active'
    @dbus_property(access=PropertyAccess.READ)
    def Category(self) -> 's': return 'ApplicationStatus'
    @dbus_property(access=PropertyAccess.READ)
    def Id(self) -> 's': return 'notchd-tray-fixture'
    @dbus_property(access=PropertyAccess.READ)
    def Title(self) -> 's': return 'Test background app'
    @dbus_property(access=PropertyAccess.READ)
    def Status(self) -> 's': return self.state
    @dbus_property(access=PropertyAccess.READ)
    def WindowId(self) -> 'u': return 0
    @dbus_property(access=PropertyAccess.READ)
    def IconName(self) -> 's': return 'utilities-terminal'
    @dbus_property(access=PropertyAccess.READ)
    def IconThemePath(self) -> 's': return ''
    @dbus_property(access=PropertyAccess.READ)
    def IconPixmap(self) -> 'a(iiay)': return []
    @dbus_property(access=PropertyAccess.READ)
    def OverlayIconName(self) -> 's': return ''
    @dbus_property(access=PropertyAccess.READ)
    def AttentionIconName(self) -> 's': return 'dialog-information'
    @dbus_property(access=PropertyAccess.READ)
    def AttentionIconPixmap(self) -> 'a(iiay)': return []
    @dbus_property(access=PropertyAccess.READ)
    def ToolTip(self) -> '(sa(iiay)ss)': return ['utilities-terminal', [], 'Test background app', 'Isolated fixture']
    @dbus_property(access=PropertyAccess.READ)
    def ItemIsMenu(self) -> 'b': return False
    @dbus_property(access=PropertyAccess.READ)
    def Menu(self) -> 'o': return '/Menu'
    @method()
    def Activate(self, x: 'i', y: 'i'): log(['activate'])
    @method()
    def SecondaryActivate(self, x: 'i', y: 'i'): log(['secondary'])
    @method()
    def ContextMenu(self, x: 'i', y: 'i'): log(['context'])
    @method()
    def Scroll(self, delta: 'i', orientation: 's'): log(['scroll', delta, orientation])
    @signal()
    def NewStatus(self, status: 's') -> 's': return status


async def main():
    bus = await MessageBus().connect()
    notifier = Notifier()
    bus.export('/StatusNotifierItem', notifier)
    bus.export('/Menu', Menu())
    for _ in range(100):
        try:
            intro = await bus.introspect('org.kde.StatusNotifierWatcher', '/StatusNotifierWatcher')
            watcher = bus.get_proxy_object('org.kde.StatusNotifierWatcher', '/StatusNotifierWatcher', intro).get_interface('org.kde.StatusNotifierWatcher')
            await watcher.call_register_status_notifier_item(bus.unique_name)
            break
        except Exception:
            await asyncio.sleep(0.05)
    else: raise RuntimeError('No tray watcher')
    print('NOTIFIER_REGISTERED', flush=True)
    if '--live' in sys.argv:
        await asyncio.Future()
    for state in ['NeedsAttention', 'Passive']:
        await asyncio.sleep(1.5)
        notifier.state = state
        notifier.NewStatus(state)
    await asyncio.sleep(1.5)
    bus.disconnect()
    print('NOTIFIER_DISCONNECTED', flush=True)


asyncio.run(main())
