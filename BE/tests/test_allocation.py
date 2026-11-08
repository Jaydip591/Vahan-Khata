from datetime import date
from decimal import Decimal as D

from apps.ledger.allocation import PaymentAmount, TripAmount, allocate, pay_status


def trip(i, day, bhada):
    return TripAmount(f"t{i}", date(2026, 11, day), i, D(bhada))


def test_no_payments_means_nothing_paid():
    a = allocate([trip(1, 1, "100")], [])
    assert a.paid == {"t1": D(0)} and a.credit == D(0)


def test_no_trips_all_money_is_credit():
    assert allocate([], [PaymentAmount(D("50"))]).credit == D("50")


def test_advance_goes_to_its_own_trip_not_the_oldest():
    trips = [trip(1, 1, "100"), trip(2, 5, "100")]
    a = allocate(trips, [PaymentAmount(D("40"), "t2")])
    assert a.paid == {"t1": D(0), "t2": D(40)}


def test_advance_larger_than_its_trip_spills_over_to_oldest():
    trips = [trip(1, 1, "100"), trip(2, 5, "50")]
    a = allocate(trips, [PaymentAmount(D("80"), "t2")])
    assert a.paid == {"t1": D(30), "t2": D(50)}
    assert a.credit == D(0)


def test_general_payments_settle_oldest_trip_first():
    trips = [trip(2, 9, "100"), trip(1, 1, "100"), trip(3, 20, "100")]  # given out of order
    a = allocate(trips, [PaymentAmount(D("150"))])
    assert a.paid == {"t1": D(100), "t2": D(50), "t3": D(0)}


def test_overpayment_becomes_credit():
    a = allocate([trip(1, 1, "100")], [PaymentAmount(D("130"))])
    assert a.paid == {"t1": D(100)} and a.credit == D(30)


def test_payment_linked_to_missing_trip_counts_as_general_money():
    a = allocate([trip(1, 1, "100")], [PaymentAmount(D("60"), "gone")])
    assert a.paid == {"t1": D(60)}


def test_same_day_trips_follow_creation_order():
    trips = [trip(2, 3, "100"), trip(1, 3, "100")]
    a = allocate(trips, [PaymentAmount(D("100"))])
    assert a.paid == {"t1": D(100), "t2": D(0)}


def test_money_stays_exact():
    a = allocate([trip(1, 1, "0.30")], [PaymentAmount(D("0.10")), PaymentAmount(D("0.20"))])
    assert a.paid["t1"] == D("0.30")


def test_pay_status():
    assert pay_status(D(100), D(0)) == "unpaid"
    assert pay_status(D(100), D(1)) == "partial"
    assert pay_status(D(100), D(100)) == "paid"
