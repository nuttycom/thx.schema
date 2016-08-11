import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.schema.*;
import thx.schema.algebra.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestSchema());
    runner.addCase(new TestSchemaDynamicExtensions());
    runner.addCase(new TestAlgSchema());
    Report.create(runner);
    runner.run();
  }
}
