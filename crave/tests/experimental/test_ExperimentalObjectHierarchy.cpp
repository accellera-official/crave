//****************************************************************************************
//	MIT License
//****************************************************************************************
//	Copyright (c) 2012-2020 University of Bremen, Germany. 
//  	Copyright (c) 2015-2020 DFKI GmbH Bremen, Germany.
//  	Copyright (c) 2020 Johannes Kepler University Linz, Austria.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.
//****************************************************************************************

#include <boost/test/unit_test.hpp>

#include <crave/experimental/Object.hpp>

#include <vector>

using namespace crave;

BOOST_FIXTURE_TEST_SUITE(ObjectHierarchy, Context_Fixture)

struct base_object : crv_object {
  base_object(crv_object_name) {}
};

struct random_object1 : crv_object {
  base_object v1{"v1"};
  base_object v2{"v2"};
  random_object1(crv_object_name) {}
  virtual ~random_object1() { }
};

struct random_object2 : crv_object {
  random_object1 obj{"obj"};
  base_object v3{"v3"};

  random_object2(crv_object_name) {}
  virtual ~random_object2() { }
};

struct random_object3 : crv_object {
  random_object1 obj{"obj"};
  base_object v3{"v3"};

  random_object1* obj1;

  random_object3(crv_object_name);
  virtual ~random_object3() { delete obj1; }
};

random_object3::random_object3(crv_object_name) {
  obj1 = new random_object1{"obj1_ptr"};
  random_object2 tmp{"tmp"};
}

BOOST_AUTO_TEST_CASE(basic_test) {
  random_object1 o1{"o1"};
  random_object2 o2{"o2"};
  random_object3 o3{"o3"};
  crv_object::root()->print_object_hierarchy();
  BOOST_REQUIRE_EQUAL(crv_object::count(), 16);

  BOOST_REQUIRE(crv_object::find("root") == nullptr);

  BOOST_REQUIRE_EQUAL(crv_object::find("o1"), &o1);
  BOOST_REQUIRE_EQUAL(crv_object::find("o1.v1"), &o1.v1);
  BOOST_REQUIRE_EQUAL(crv_object::find("o1.v2"), &o1.v2);

  BOOST_REQUIRE_EQUAL(crv_object::find("o2"), &o2);
  BOOST_REQUIRE_EQUAL(crv_object::find("o2.obj"), &o2.obj);
  BOOST_REQUIRE_EQUAL(crv_object::find("o2.v3"), &o2.v3);

  BOOST_REQUIRE_EQUAL(crv_object::find("o3"), &o3);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.obj"), &o3.obj);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.v3"), &o3.v3);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.obj1_ptr"), o3.obj1);
}

struct random_object4 : public random_object2 {
  random_object1 other_obj{"other_obj"};

  random_object4(crv_object_name name) : random_object2(name) {}
};

struct random_object5 : public random_object4 {
  random_object5(crv_object_name name) : random_object4(name) {}
};

BOOST_AUTO_TEST_CASE(inheritance_test) {
  random_object5 o5{"o5"};
  random_object3 o3{"o3"};

  BOOST_REQUIRE_EQUAL(crv_object::find("o5"), &o5);
  BOOST_REQUIRE_EQUAL(crv_object::find("o5.obj"), &o5.obj);
  BOOST_REQUIRE_EQUAL(crv_object::find("o5.v3"), &o5.v3);
  BOOST_REQUIRE_EQUAL(crv_object::find("o5.other_obj"), &o5.other_obj);

  BOOST_REQUIRE_EQUAL(crv_object::find("o3"), &o3);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.obj"), &o3.obj);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.v3"), &o3.v3);
  BOOST_REQUIRE_EQUAL(crv_object::find("o3.obj1_ptr"), o3.obj1);
}

BOOST_AUTO_TEST_SUITE_END()  // ObjectHierarchy

//  vim: ft=cpp:ts=2:sw=2:expandtab
