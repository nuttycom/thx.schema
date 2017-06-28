package thx.schema;

import thx.schema.SimpleSchema.*;
import thx.schema.Core.*;

class TestCore extends TestBase {
  public function testBigInt() {
    roundTripSchema(thx.BigInt.fromString('123434534534534'), bigInt());
  }

  public function testDate() {
    roundTripSchema(Date.fromString("2015-03-29"), date());
    failDeserialization('x', date());
  }

  public function testDateTime() {
    roundTripSchema(thx.DateTime.fromString("2015-03-29"), dateTime());
    failDeserialization('x', dateTime());
  }

  public function testDateTimeUtc() {
    roundTripSchema(thx.DateTimeUtc.fromString("2015-03-29"), dateTimeUtc());
    failDeserialization('x', dateTimeUtc());
  }

  public function testDecimal() {
    roundTripSchema(thx.Decimal.fromString("123434534534534.0002342"), decimal());
  }

  public function testInt64() {
    roundTripSchema(haxe.Int64.parseString('123434534534'), int64());
    failDeserialization('x', int64());
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

  public function testJson() {
    roundTripSchema({"a": "b", "c": [1,2,3] }, json());
    failDeserialization('{a:"b"}', json());
  }

  public function testNel() {
    roundTripSchema(Nel.pure("a"), nel(string()));
    failDeserialization([], nel(string()));
  }

  public function testPath() {
    roundTripSchema(thx.Path.fromString("/some/path"), path());
  }

  public function testQueryString() {
    roundTripSchema(thx.QueryString.parse("q=yay"), queryString());
  }

  public function testRational() {
    roundTripSchema(thx.Rational.fromString('10/3'), rational());
  }

  public function testReadonlyArray() {
    roundTripSchema(([1,2,3] : thx.ReadonlyArray<Int>), readonlyArray(int()));
  }

  public function testTime() {
    roundTripSchema(thx.Time.fromString("25:30:58.0123"), time());
    failDeserialization('x', time());
  }

  public function testUrl() {
    roundTripSchema(thx.Url.fromString("http://google.com/?q=yay"), url());
  }
}
