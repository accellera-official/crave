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


#include "../crave/ir/visitor/ToDotNodeVisitor.hpp"

namespace crave {

std::ostream &Node::printDot(std::ostream &out) const {
  ToDotVisitor v(out);
  this->visit(&v);
  return out;
}

bool ToDotVisitor::putNode(Node const *n) {
  if (nodes_.find(n) != nodes_.end()) return false;

  nodes_.insert(n);
  return true;
}

void ToDotVisitor::visitNode(Node const &n) { out_ << "\t" << reinterpret_cast<size_t>(&n); }

void ToDotVisitor::visitTerminal(Terminal const &t) { out_ << " is " << (t.sign() ? "s" : "u") << t.bitsize(); }

void ToDotVisitor::visitUnaryExpr(UnaryExpression const &ue) {
  ue.child()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&ue) << " -> " << reinterpret_cast<size_t>(ue.child().get()) << std::endl;
}

void ToDotVisitor::visitUnaryOpr(UnaryOperator const &) { out_ << "UnOp"; }

void ToDotVisitor::visitBinaryExpr(BinaryExpression const &be) {
  be.lhs()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&be) << " -> " << reinterpret_cast<size_t>(be.lhs().get()) << std::endl;
  be.rhs()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&be) << " -> " << reinterpret_cast<size_t>(be.rhs().get()) << std::endl;
}

void ToDotVisitor::visitBinaryOpr(BinaryOperator const &) { out_ << "BinOp"; }

void ToDotVisitor::visitTernaryExpr(TernaryExpression const &te) {
  te.a()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&te) << " -> " << reinterpret_cast<size_t>(te.a().get()) << std::endl;
  te.b()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&te) << " -> " << reinterpret_cast<size_t>(te.b().get()) << std::endl;
  te.c()->visit(this);
  out_ << "\t" << reinterpret_cast<size_t>(&te) << " -> " << reinterpret_cast<size_t>(te.c().get()) << std::endl;
}

void ToDotVisitor::visitPlaceholder(Placeholder const &pl) {
  if (putNode(&pl)) {
    visitNode(pl);
    out_ << " [label=\"placeholder: " << pl.id() << "\"]" << std::endl;
  }
}

void ToDotVisitor::visitVariableExpr(VariableExpr const &ve) {
  if (putNode(&ve)) {
    visitNode(ve);
    out_ << " [label=\"variable: " << ve.id();
    visitTerminal(ve);
    out_ << "\"]" << std::endl;
  }
}

void ToDotVisitor::visitConstant(Constant const &c) {
  if (putNode(&c)) {
    visitNode(c);
    out_ << " [label=\"constant: ";
    if (c.sign())
      out_ << static_cast<long>(c.value());
    else
      out_ << c.value();
    visitTerminal(c);
    out_ << "\"]\n";
  }
}

void ToDotVisitor::visitVectorExpr(VectorExpr const &ve) {
  if (putNode(&ve)) {
    visitNode(ve);
    out_ << " [label=\"vector variable: " << ve.id();
    visitTerminal(ve);
    out_ << "\"]" << std::endl;
  }
}

void ToDotVisitor::visitNotOpr(NotOpr const &o) { unaryOperator(o, "not (!)"); }

void ToDotVisitor::visitNegOpr(NegOpr const &o) { unaryOperator(o, "neg (-)"); }

void ToDotVisitor::visitComplementOpr(ComplementOpr const &o) { unaryOperator(o, "complement (~)"); }

void ToDotVisitor::visitInside(Inside const &o) {
  if (putNode(&o)) {
    visitNode(o);
    out_ << " [label=\"inside\n{ ";
    for (uint64_t u : o.collection()) { out_ << u << " "; }
    out_ << "}\"]" << std::endl;
  }
  visitUnaryExpr(o);
}

void ToDotVisitor::visitExtendExpr(ExtendExpression const &e) {
  if (putNode(&e)) {
    visitNode(e);
    out_ << " [label=\"extend by " << e.value() << "\"]" << std::endl;
  }
  visitUnaryExpr(e);
}

void ToDotVisitor::visitLogicalAndOpr(LogicalAndOpr const &o) { binaryOperator(o, "and (&&)"); }

void ToDotVisitor::visitLogicalOrOpr(LogicalOrOpr const &o) { binaryOperator(o, "or (||)"); }

void ToDotVisitor::visitAndOpr(AndOpr const &o) { binaryOperator(o, "and (&)"); }

void ToDotVisitor::visitOrOpr(OrOpr const &o) { binaryOperator(o, "or (|)"); }

void ToDotVisitor::visitXorOpr(XorOpr const &o) { binaryOperator(o, "xor (^)"); }

void ToDotVisitor::visitEqualOpr(EqualOpr const &o) { binaryOperator(o, "equal (==)"); }

void ToDotVisitor::visitNotEqualOpr(NotEqualOpr const &o) { binaryOperator(o, "not_equal (!=)"); }

void ToDotVisitor::visitLessOpr(LessOpr const &o) { binaryOperator(o, "less (<)"); }

void ToDotVisitor::visitLessEqualOpr(LessEqualOpr const &o) { binaryOperator(o, "less_equal (<=)"); }

void ToDotVisitor::visitGreaterOpr(GreaterOpr const &o) { binaryOperator(o, "greater (>)"); }

void ToDotVisitor::visitGreaterEqualOpr(GreaterEqualOpr const &o) { binaryOperator(o, "greater_equal (>=)"); }

void ToDotVisitor::visitPlusOpr(PlusOpr const &o) { binaryOperator(o, "plus (+)"); }

void ToDotVisitor::visitMinusOpr(MinusOpr const &o) { binaryOperator(o, "minus (-)"); }

void ToDotVisitor::visitMultipliesOpr(MultipliesOpr const &o) { binaryOperator(o, "multiplies (*)"); }

void ToDotVisitor::visitDevideOpr(DevideOpr const &o) { binaryOperator(o, "divide (/)"); }

void ToDotVisitor::visitModuloOpr(ModuloOpr const &o) { binaryOperator(o, "modulo (%)"); }

void ToDotVisitor::visitShiftLeftOpr(ShiftLeftOpr const &o) { binaryOperator(o, "shift_left (<<)"); }

void ToDotVisitor::visitShiftRightOpr(ShiftRightOpr const &o) { binaryOperator(o, "shift_right (>>)"); }

void ToDotVisitor::visitVectorAccess(VectorAccess const &o) {
  if (putNode(&o)) {
    visitNode(o);
    out_ << " [label=\"vector_access ([])\"]" << std::endl;
  }
  visitBinaryExpr(o);
}

void ToDotVisitor::visitIfThenElse(IfThenElse const &ite) {
  if (putNode(&ite)) {
    visitNode(ite);
    out_ << " [label=\"if_then_else (?:)\"]" << std::endl;
  }
  visitTernaryExpr(ite);
}

void ToDotVisitor::visitForEach(ForEach const &fe) {
  if (putNode(&fe)) {
    visitNode(fe);
    out_ << " [label=\"for_each \"]" << std::endl;
  }
  visitBinaryExpr(fe);
}

void ToDotVisitor::visitUnique(Unique const &u) { unaryOperator(u, "unique"); }

void ToDotVisitor::visitBitslice(Bitslice const &b) {
  if (putNode(&b)) {
    visitNode(b);
    out_ << " [label=\"bitslice (" << b.r() << ":" << b.l() << ") \"]" << std::endl;
  }
  visitUnaryExpr(b);
}

}  // namespace crave
