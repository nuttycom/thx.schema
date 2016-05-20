import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.schema.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestSchema());
    runner.addCase(new TestSchemaDynamicExtensions());
    Report.create(runner);
    runner.run();
  }
}
