package thx.schema;

import thx.schema.SimpleSchema.*;
import thx.schema.Core.*;

class TestCore extends TestBase {
  public function testNel() {
    roundTripSchema(Nel.pure("a"), nel(string()));
    failDeserialization([], nel(string()));
  }

  public function testJson() {
    roundTripSchema({"a": "b", "c": [1,2,3] }, json());
    failDeserialization('{a:"b"}', json());
  }

  public function testDateTime() {
    roundTripSchema(thx.DateTime.fromString("2015-03-29"), dateTime());
    failDeserialization('x', dateTime());
  }

  public function testDateTimeUtc() {
    roundTripSchema(thx.DateTimeUtc.fromString("2015-03-29"), dateTimeUtc());
    failDeserialization('x', dateTimeUtc());
  }

  public function testLocalDate() {
    roundTripSchema(thx.LocalDate.fromString("2015-03-29"), localDate());
    failDeserialization('x', localDate());
  }

  public function testLocalMonthDay() {
    roundTripSchema(thx.LocalMonthDay.fromString("--03-29"), localMonthDay());
    failDeserialization('x', localMonthDay());
  }

  public function testLocalYearMonth() {
    roundTripSchema(thx.LocalYearMonth.fromString("2017-12"), localYearMonth());
    failDeserialization('x', localYearMonth());
  }

  public function testTime() {
    roundTripSchema(thx.Time.fromString("25:30:58.0123"), time());
    failDeserialization('x', time());
  }
}
