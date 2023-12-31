import "helpers.spec"

methods {
    // library
    add(bytes32)      returns (bool)    envfree
    remove(bytes32)   returns (bool)    envfree
    contains(bytes32) returns (bool)    envfree
    length()          returns (uint256) envfree
    at_(uint256)      returns (bytes32) envfree

    // FV
    _indexOf(bytes32) returns (uint256) envfree
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Helpers                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
function sanity() returns bool {
    return length() < max_uint256;
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Invariant: All indexed keys are contained                                                                           │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
invariant indexedContained(uint256 index)
    index < length() => contains(at_(index))
    {
        preserved {
            requireInvariant consistencyIndex(index);
            requireInvariant consistencyIndex(to_uint256(length() - 1));
        }
    }

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Invariant: A value can only be stored at a single location                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
invariant atUniqueness(uint256 index1, uint256 index2)
    index1 == index2 <=> at_(index1) == at_(index2)
    {
        preserved remove(bytes32 key) {
            requireInvariant atUniqueness(index1, to_uint256(length() - 1));
            requireInvariant atUniqueness(index2, to_uint256(length() - 1));
        }
    }

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Invariant: index <> key relationship is consistent                                                                  │
│                                                                                                                     │
│ Note that the two consistencyXxx invariants, put together, prove that at_ and _indexOf are inverse of one another.  │
│ This proves that we have a bijection between indices (the enumerability part) and keys (the entries that are added  │
│ and removed from the EnumerableSet).                                                                                │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
invariant consistencyIndex(uint256 index)
    index < length() => _indexOf(at_(index)) == index + 1
    {
        preserved remove(bytes32 key) {
            requireInvariant consistencyIndex(to_uint256(length() - 1));
        }
    }

invariant consistencyKey(bytes32 key)
    contains(key) => (
        _indexOf(key) > 0 &&
        _indexOf(key) <= length() &&
        at_(to_uint256(_indexOf(key) - 1)) == key
    )
    {
        preserved remove(bytes32 otherKey) {
            requireInvariant consistencyKey(otherKey);
            requireInvariant atUniqueness(
                to_uint256(_indexOf(key) - 1),
                to_uint256(_indexOf(otherKey) - 1)
            );
        }
    }

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: state only changes by adding or removing elements                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule stateChange(env e, bytes32 key) {
    require sanity();
    requireInvariant consistencyKey(key);

    uint256 lengthBefore   = length();
    bool    containsBefore = contains(key);

    method f;
    calldataarg args;
    f(e, args);

    uint256 lengthAfter   = length();
    bool    containsAfter = contains(key);

    assert lengthBefore != lengthAfter => (
        (f.selector == add(bytes32).selector    && lengthAfter == lengthBefore + 1) ||
        (f.selector == remove(bytes32).selector && lengthAfter == lengthBefore - 1)
    );

    assert containsBefore != containsAfter => (
        (f.selector == add(bytes32).selector    && containsAfter) ||
        (f.selector == remove(bytes32).selector && containsBefore)
    );
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: check liveness of view functions.                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule liveness_1(bytes32 key) {
    requireInvariant consistencyKey(key);

    // contains never revert
    contains@withrevert(key);
    assert !lastReverted;
}

rule liveness_2(uint256 index) {
    requireInvariant consistencyIndex(index);

    // length never revert
    uint256 length = length@withrevert();
    assert !lastReverted;

    // at reverts iff the index is out of bound
    at_@withrevert(index);
    assert !lastReverted <=> index < length;
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: add key to EnumerableSet if not already contained                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule add(bytes32 key, bytes32 otherKey) {
    require sanity();

    uint256 lengthBefore        = length();
    bool    containsBefore      = contains(key);
    bool    containsOtherBefore = contains(otherKey);

    bool added = add@withrevert(key);
    bool success = !lastReverted;

    assert success && contains(key),
        "liveness & immediate effect";

    assert added <=> !containsBefore,
        "return value: added iff not contained";

    assert length() == lengthBefore + to_mathint(added ? 1 : 0),
        "effect: length increases iff added";

    assert added => at_(lengthBefore) == key,
        "effect: add at the end";

    assert containsOtherBefore != contains(otherKey) => (added && key == otherKey),
        "side effect: other keys are not affected";
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: remove key from EnumerableSet if already contained                                                            │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule remove(bytes32 key, bytes32 otherKey) {
    requireInvariant consistencyKey(key);
    requireInvariant consistencyKey(otherKey);

    uint256 lengthBefore        = length();
    bool    containsBefore      = contains(key);
    bool    containsOtherBefore = contains(otherKey);

    bool removed = remove@withrevert(key);
    bool success = !lastReverted;

    assert success && !contains(key),
        "liveness & immediate effect";

    assert removed <=> containsBefore,
        "return value: removed iff contained";

    assert length() == lengthBefore - to_mathint(removed ? 1 : 0),
        "effect: length decreases iff removed";

    assert containsOtherBefore != contains(otherKey) => (removed && key == otherKey),
        "side effect: other keys are not affected";
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: when adding a new key, the other keys remain in set, at the same index.                                       │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule addEnumerability(bytes32 key, uint256 index) {
    require sanity();

    bytes32 atBefore = at_(index);
    add(key);
    bytes32 atAfter = at_@withrevert(index);
    bool atAfterSuccess = !lastReverted;

    assert atAfterSuccess;
    assert atBefore == atAfter;
}

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Rule: when removing a existing key, the other keys remain in set, at the same index (except for the last one).      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
rule removeEnumerability(bytes32 key, uint256 index) {
    uint256 last = length() - 1;

    requireInvariant consistencyKey(key);
    requireInvariant consistencyIndex(index);
    requireInvariant consistencyIndex(last);

    bytes32 atBefore = at_(index);
    bytes32 lastBefore = at_(last);

    remove(key);

    // can't read last value (length decreased)
    bytes32 atAfter = at_@withrevert(index);
    assert lastReverted <=> index == last;

    // One value that is allowed to change is if previous value was removed,
    // in that case the last value before took its place.
    assert (
        index != last &&
        atBefore != atAfter
    ) => (
        atBefore == key &&
        atAfter == lastBefore
    );
}
