//****************************************************************************************
//	MIT License
//****************************************************************************************
//	Copyright (c) 2012-2020 University of Bremen, Germany. 
//  	Copyright (c) 2015-2020 DFKI GmbH Bremen, Germany.
//  	Copyright (c) 2020 Johannes Kepler University Linz, Austria.
//      Copyright (c) 2022 - 2023 Coseda Technologies GmbH.
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

#include "../../crave/experimental/SequenceItem.hpp"
#include "../../crave/backend/Generator.hpp"

namespace crave
{
  crv_sequence_item::crv_sequence_item() : gen_(), built_(false), cloned_(false) {}

  crv_sequence_item::crv_sequence_item(crv_sequence_item const & other) : crv_object(other), gen_(), built_(false), cloned_(true) {}

  std::string crv_sequence_item::obj_kind() const { return "crv_sequence_item"; }

  void crv_sequence_item :: crosscheck_constraints () {

	  if (!built_) {
		  gen_ = std::make_shared<Generator>();
		  auto local_var_ctn = check_default_constraints(*gen_);
		  std::map<int, int> dist = local_var_ctn->dist_ref_to_var_map;

		  for (auto obj : children_) {
			  bool flag = false;
			  crave::crv_var* local_var = dynamic_cast< crave::crv_var* >(obj);
			  if (local_var != nullptr) {
				  for (auto out_it : dist) {
					  if ((local_var->getVarID() == out_it.second) && (!flag)) {
						  flag = true;
					  }
					  else if ((local_var->getVarID() == out_it.second) && (flag)) {
						  crave::crv_constraint* cntr = dynamic_cast< crave::crv_constraint* >(obj->children_.front());
						  if (cntr != nullptr){
							  cntr->deactivate();

							  break;
						  }
					  }
				  }
			  }
		  }
	  }
  }

  bool crv_sequence_item::randomize() {
    assert(!cloned_ && "cloned crv_sequence_item cannot be randomized");
    crosscheck_constraints() ;

    if (!built_) {
      gen_ = std::make_shared<Generator>();
      recursive_build(*gen_);
      built_ = true;
    }
    return gen_->nextCov();
  }
  
  void crv_sequence_item::goal(crv_covergroup& group) {
    for (auto e : group.bound_var_expr_list()) (*gen_)(e);
    for (auto e : group.uncovered_as_list()) gen_->cover(e);
  }
    
  void crv_sequence_item::request_rebuild() {
    built_ = false;
    gen_.reset();
    crv_object::request_rebuild();
  }

  bool crv_sequence_item::randomize_with_expr_list(const expression_list & list) {
    assert(!cloned_ && "cloned crv_sequence_item cannot be randomized");
    // TODO Generator caching
    rand_with_gen_ = std::make_shared<Generator>();
    recursive_build(*rand_with_gen_);
    for (auto e : list) (*rand_with_gen_)(e);
    return rand_with_gen_->next();
  }

}
