//----------------------------------------------------------------------
//  Licensed to Accellera Systems Initiative Inc. (Accellera) 
//  under one or more contributor license agreements.  
//  See the NOTICE file distributed with this work for 
//  additional information regarding copyright ownership.
//
//  Accellera licenses this file to you under the Apache 
//  License, Version 2.0 (the "License"); you may not use 
//  this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in
//  writing, software distributed under the License is
//  distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//  CONDITIONS OF ANY KIND, either express or implied.  See
//  the License for the specific language governing
//  permissions and limitations under the License.
//----------------------------------------------------------------------

/*! \file crave2uvm.h
    \brief Include this file to get all Crave2UVM functionality.

    This file contains all includes and macros you need to get started with Crave2UVM.
    It includes the two adapter classes and redefines UVM_DO_ON_PRI_WITH in order to
 *  add random verification with constraints.
 */

#pragma once
#include "uvm_randomized_sequence_item.h"
#include "uvm_randomized_sequence.h"


#define UNPACK(...) __VA_ARGS__


#undef UVM_DO
#define UVM_DO(SEQ_OR_ITEM) \
  UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, this->m_sequencer, -1,)

#undef UVM_DO_WITH
#define UVM_DO_WITH(SEQ_OR_ITEM, CONSTRAINTS) \
	UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, this->m_sequencer, -1, UNPACK CONSTRAINTS)

#undef UVM_DO_PRI
#define UVM_DO_PRI(SEQ_OR_ITEM, PRIORITY) \
  UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, this->m_sequencer, PRIORITY,)

#undef UVM_DO_ON
#define UVM_DO_ON(SEQ_OR_ITEM, SEQR) \
  UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, SEQR, -1,)

#undef UVM_DO_ON_PRI
#define UVM_DO_ON_PRI(SEQ_OR_ITEM, SEQR, PRIORITY) \
  UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, SEQR, PRIORITY,)

/*! \def UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, SEQR, PRIORITY, CONSTRAINTS)
    \brief Redefine UVM_DO_ON_PRI_WITH to use in \a CONSTRAINTS with CRAVE.
 */
#undef UVM_DO_ON_PRI_WITH
#define UVM_DO_ON_PRI_WITH(SEQ_OR_ITEM, SEQR, PRIORITY, CONSTRAINTS) \
  { \
  ::uvm::uvm_sequence_base* seq__; \
  UVM_CREATE_ON(SEQ_OR_ITEM, SEQR) \
  seq__ = dynamic_cast<uvm::uvm_sequence_base*>(SEQ_OR_ITEM); \
  if (seq__ == NULL) this->start_item(SEQ_OR_ITEM, PRIORITY); \
  if (seq__ == NULL && !SEQ_OR_ITEM->randomize_with(CONSTRAINTS)) \
    UVM_WARNING("RNDFLD", "Randomization failed in uvm_do_with action"); \
  if (seq__ == NULL) this->finish_item(SEQ_OR_ITEM, PRIORITY); \
  else seq__->start(SEQR, this, PRIORITY, 0); \
  } \

