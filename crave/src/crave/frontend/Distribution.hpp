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

#include <random>
#include <limits>
#include <vector>
#include <stdexcept>
	
#include "ConstraintType.hpp"
#include "WeightedRange.hpp"
#include "../RandomSeedManager.hpp"

namespace crave {

extern RandomSeedManager rng;

template <typename T>
struct distribution_tag;

/*
 * Workaround for the issue that std::uniform_int_distribution is undefined for char,
 * unsigned char and signed char.
 */
template <typename T, typename Generator>
T uniformly_distributed_value(T const& left, T const& right, Generator& gen) {
  return std::uniform_int_distribution<T>(left, right)(gen);
}

template <typename Generator>
char uniformly_distributed_value(char const& left, char const& right, Generator& gen) {
  return std::uniform_int_distribution<int>(left, right)(gen);
}

template <typename Generator>
signed char uniformly_distributed_value(signed char const& left, signed char const& right, Generator& gen) {
  return std::uniform_int_distribution<int>(left, right)(gen);
}

template <typename Generator>
unsigned char uniformly_distributed_value(unsigned char const& left, unsigned char const& right, Generator& gen) {
  return std::uniform_int_distribution<int>(left, right)(gen);
}

/*!
 * \ingroup oldAPI
 * \ingroup newAPI
 * \brief Distribution of values to used in constraints.
 * 
 * This class allows you to create a distribution.
 * You can use crave::dist operator to force a variable to be inside a distribution.
 * A distribution is defined by ranges.
 * For details see crave::range and crave::weighted_range.
 */
template <typename T>
struct distribution {
  /*!
   * \brief Defines an empty distribution.
   * 
   * An empty distribution with no ranges corresponds to the whole value range of the base type T.
   */
  distribution() : ranges_() {}

  /*!
   * \brief Defines a distribution with a weighted range
   * 
   * A weighted range uses weights to define which values should occur more often.
   * See crave::weighted_range for details.
   * 
   * \param range weighted range for distribution
   */
  distribution(const weighted_range<T>& range) { addRange(range); }

  /**
   * \brief Adds another range to the distribution.
   * 
   * \param range A weighted range to add to this distribution
   * \return reference to this distribution
   */
  distribution& operator()(const weighted_range<T>& range) {
    addRange(range);
    return *this;
  }

  /**
   * \brief Creates a distribution to use in constraints.
   * 
   * This method creates a distribution_tag<T> which is recognized by the constraint frontend.
   * Typically this is an input argument for crave::dist.
   * 
   * \param range A (weighted) range to create a distribution of.
   * \return distribution_tag<T> for constraint definition
   */
  static distribution_tag<T> create(const weighted_range<T>& range) { return distribution_tag<T>(distribution(range)); }

  /**
   * \brief Creates a simple distribution with given left and right bound.
   * 
   * This method creates a distribution_tag<T> which is recognized by the constraint frontend.
   * It internally creates an equally distributed range from left to right bound.
   * 
   * \param left left bound of the range
   * \param right right bound of the range
   * \return distribution_tag<T> for constraint definition
   */
  static distribution_tag<T> simple_range(T left, T right) {
    return distribution_tag<T>(distribution(range<T>(left, right)));
  }

  /**
   * \brief Deletes all ranges of this distribution
   */
  void reset() { ranges_.clear(); }

  /**
   * \brief Get all ranges of this distribution.
   * \return weighted ranges of this distribution
   */
  std::vector<weighted_range<T> > const& ranges() const { return ranges_; }

  /**
   * \brief Generate next random distribution value.
   * 
   * If no ranges exist for this distribution, an uniform distribution over all possible values of T is used.
   * 
   * \return T Next random value based on specified weights of ranges.
   */
  T nextValue() const {
    if (ranges_.empty()) {
      return uniformly_distributed_value(std::numeric_limits<T>::min(), std::numeric_limits<T>::max(), *rng.get());
    }
    weighted_range<T> selected = ranges_.back();
    if (ranges_.size() > 1) {
      uint64_t r = std::uniform_int_distribution<uint64_t>(0, selected.accumWeight_ - 1)(*rng.get());
      for (unsigned i = 0; i < ranges_.size(); i++)
        if (r < ranges_[i].accumWeight_) {
          selected = ranges_[i];
          break;
        }
    }
    return uniformly_distributed_value(selected.left_, selected.right_, *rng.get());
  }

 protected:
  void addRange(weighted_range<T> wr) {
    for (unsigned i = 0; i < ranges_.size(); i++)
      if (ranges_[i].overlap(wr)) {
        throw std::runtime_error("Overlapping range exists.");
      }
    if (ranges_.empty()) {
      wr.accumWeight_ = wr.weight_;
    } else {
      wr.accumWeight_ = ranges_.back().accumWeight_ + wr.weight_;
    }
    ranges_.push_back(wr);
  }

 protected:
  std::vector<weighted_range<T> > ranges_;
};

template <>
struct distribution<bool> {
  explicit distribution(const double prob = 0.5);

  static distribution_tag<bool> create(const double prob);

  bool nextValue() const;

  std::vector<weighted_range<bool> > const& ranges() const;

 private:
  double prob_;
};

template <typename T>
struct distribution_tag : public Constraint<typename boost::proto::terminal<distribution<T> >::type> {
  typedef Constraint<typename boost::proto::terminal<distribution<T> >::type> base_type;
  explicit distribution_tag(distribution<T> d) : base_type(boost::proto::make_expr<boost::proto::tag::terminal>(d)) {}

  distribution_tag& operator()(const weighted_range<T>& range) {
    boost::proto::value (*this)(range);
    return *this;
  }
};

}  // namespace crave
