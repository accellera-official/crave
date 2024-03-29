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


#pragma once

namespace crave {

class Node;
class Placeholder;
class Terminal;
class VariableExpr;
class Constant;
class VectorExpr;
class UnaryExpression;
class UnaryOperator;
class BinaryOperator;
class BinaryExpression;
class ExtendExpression;
class TernaryExpression;

// logical
class NotOpr;
class LogicalAndOpr;
class LogicalOrOpr;

// comparison
class EqualOpr;
class NotEqualOpr;
class LessOpr;
class LessEqualOpr;
class GreaterOpr;
class GreaterEqualOpr;

// bitwise
class NegOpr;
class ComplementOpr;
class AndOpr;
class OrOpr;
class XorOpr;
class ShiftLeftOpr;
class ShiftRightOpr;
class Bitslice;

// arithmetic
class PlusOpr;
class MinusOpr;
class MultipliesOpr;
class DevideOpr;
class ModuloOpr;

// misc
class Inside;
class IfThenElse;

// vector
class VectorAccess;
class ForEach;
class Unique;

class NodeVisitor {
 protected:
  NodeVisitor() {}
  virtual ~NodeVisitor() {}

 public:
  virtual void visitNode(Node const&) = 0;
  virtual void visitTerminal(Terminal const&) = 0;
  virtual void visitUnaryExpr(UnaryExpression const&) = 0;
  virtual void visitUnaryOpr(UnaryOperator const&) = 0;
  virtual void visitBinaryExpr(BinaryExpression const&) = 0;
  virtual void visitBinaryOpr(BinaryOperator const&) = 0;
  virtual void visitTernaryExpr(TernaryExpression const&) = 0;
  virtual void visitPlaceholder(Placeholder const&) = 0;
  virtual void visitVariableExpr(VariableExpr const&) = 0;
  virtual void visitConstant(Constant const&) = 0;
  virtual void visitVectorExpr(VectorExpr const&) = 0;
  virtual void visitNotOpr(NotOpr const&) = 0;
  virtual void visitNegOpr(NegOpr const&) = 0;
  virtual void visitComplementOpr(ComplementOpr const&) = 0;
  virtual void visitInside(Inside const&) = 0;
  virtual void visitExtendExpr(ExtendExpression const&) = 0;
  virtual void visitAndOpr(AndOpr const&) = 0;
  virtual void visitOrOpr(OrOpr const&) = 0;
  virtual void visitLogicalAndOpr(LogicalAndOpr const&) = 0;
  virtual void visitLogicalOrOpr(LogicalOrOpr const&) = 0;
  virtual void visitXorOpr(XorOpr const&) = 0;
  virtual void visitEqualOpr(EqualOpr const&) = 0;
  virtual void visitNotEqualOpr(NotEqualOpr const&) = 0;
  virtual void visitLessOpr(LessOpr const&) = 0;
  virtual void visitLessEqualOpr(LessEqualOpr const&) = 0;
  virtual void visitGreaterOpr(GreaterOpr const&) = 0;
  virtual void visitGreaterEqualOpr(GreaterEqualOpr const&) = 0;
  virtual void visitPlusOpr(PlusOpr const&) = 0;
  virtual void visitMinusOpr(MinusOpr const&) = 0;
  virtual void visitMultipliesOpr(MultipliesOpr const&) = 0;
  virtual void visitDevideOpr(DevideOpr const&) = 0;
  virtual void visitModuloOpr(ModuloOpr const&) = 0;
  virtual void visitShiftLeftOpr(ShiftLeftOpr const&) = 0;
  virtual void visitShiftRightOpr(ShiftRightOpr const&) = 0;
  virtual void visitVectorAccess(VectorAccess const&) = 0;
  virtual void visitIfThenElse(IfThenElse const&) = 0;
  virtual void visitForEach(ForEach const&) = 0;
  virtual void visitUnique(Unique const&) = 0;
  virtual void visitBitslice(Bitslice const&) = 0;
};

unsigned int placeholder_bitsize();

}  // end namespace crave
