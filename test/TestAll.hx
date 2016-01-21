import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.schema.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestSchema());
    Report.create(runner);
    runner.run();
  }
}
