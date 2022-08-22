/****************************************************************************************
//	MIT License
//***************************************************************************************
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
****************************************************************************************/

#pragma once

#include "Variable.hpp"

#include "../frontend/Distribution.hpp"
#include "../frontend/bitsize_traits_sysc.hpp"

namespace crave {

template <typename T>
struct to_constant_expr<T, typename std::enable_if<is_sysc_dt<T>::value>::type> {
  Constant operator()(T value) {
    return Constant(value.to_uint64(), bitsize_traits<T>::value, crave::is_signed<T>::value);
  }
};

/**
 * crv_variable for SystemC data types
 */
template <typename T>
class crv_variable<T, typename std::enable_if<is_sysc_dt<T>::value>::type> : public crv_var, public crv_variable_base<T> {
  CRV_VARIABLE_COMMON_CONSTRUCTORS(T);
  CRV_VARIABLE_ASSIGNMENT_INTERFACE(T);
  CRV_VARIABLE_ARITHMETIC_INTERFACE(T);
  CRV_VARIABLE_BITWISE_INTERFACE(T);

  crv_constraint c_var_uniform;

 public:
  /**
   * randomize variable
   * @return true if success
   */
  bool randomize() override {
    static distribution<uint64_t> dist;
    this->value = dist.nextValue();
    return true;
  }

  void create_default_cstr () {
	  create_distribution (T());
    }

  template <typename L>
   void create_distribution (const L &tvar, typename std::enable_if<std::is_signed<L>::value, void>::type* = nullptr) {
    	  c_var_uniform = {dist(this->var, make_distribution(weighted_range<int64_t>(get_sc_dt_min_numeric_limit(tvar), get_sc_dt_max_numeric_limit(tvar),1)))};
    }

  template <typename L>
   void create_distribution (const L &tvar, typename std::enable_if<std::is_unsigned<L>::value, void>::type* = nullptr) {
    	  c_var_uniform = {dist(this->var, make_distribution(weighted_range<uint64_t>(get_sc_dt_min_numeric_limit(tvar), get_sc_dt_max_numeric_limit(tvar),1)))};
    }


  template <typename L >
  int64_t get_sc_dt_min_numeric_limit (const L &var, typename std::enable_if<std::is_signed<L>::value, void>::type* = nullptr) {
	  return (int64_t)(-(pow(2,var.length()-1)));
  }

  template <typename L>
    int64_t get_sc_dt_max_numeric_limit (const L &var, typename std::enable_if<std::is_signed<L>::value, void>::type* = nullptr) {
  	  return (int64_t)(pow(2,var.length()-1) - 1);
  	}

  template <typename L >
    uint64_t get_sc_dt_min_numeric_limit(const L &var, typename std::enable_if<std::is_unsigned<L>::value, void>::type* = nullptr) {
  	  return (uint64_t)(0);
  	}

  template <typename L >
   uint64_t get_sc_dt_max_numeric_limit (const L &var, typename std::enable_if<std::is_unsigned<L>::value, void>::type* = nullptr) {
	  return (uint64_t)(pow(2,var.length()) - 1);
  }

  unsigned getVarID() {
 	  return crv_variable_base<T>::id();
   }


};

}  // namespace crave
