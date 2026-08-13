import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // A tall, narrow window: this is a single card, not a dashboard.
    let size = NSSize(width: 720, height: 900)
    self.setContentSize(size)
    self.contentMinSize = NSSize(width: 480, height: 620)
    self.center()

    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.backgroundColor = NSColor(
      red: 0x0E / 255.0, green: 0x10 / 255.0, blue: 0x0F / 255.0, alpha: 1.0)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
