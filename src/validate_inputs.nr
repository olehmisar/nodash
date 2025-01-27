pub comptime fn validate_inputs(f: FunctionDefinition) {
    let validated_inputs = f
        .parameters()
        .map(|(name, _typ): (Quoted, Type)| quote {{ nodash::ValidateInput::validate($name); }})
        .join(quote {;});
    let checks_body = quote {{ $validated_inputs }}.as_expr().expect(
        f"failed to parse ValidateInput checks code",
    ); // should never fail

    let old_body = f.body();
    let checked_body = quote {{
        $checks_body;
        $old_body
    }};
    f.set_body(checked_body.as_expr().expect(f"failed to concatenate body with checks"));
}

#[derive_via(derive_validate_input)]
pub trait ValidateInput {
    fn validate(self);
}

comptime fn derive_validate_input(s: StructDefinition) -> Quoted {
    let name = quote { nodash::ValidateInput };
    let signature = quote { fn validate(self)  };
    let for_each_field = |name| quote { nodash::ValidateInput::validate(self.$name); };
    let body = |fields| quote {  $fields  };
    std::meta::make_trait_impl(s, name, signature, for_each_field, quote { , }, body)
}

impl ValidateInput for u8 {
    fn validate(self) {}
}

impl ValidateInput for u16 {
    fn validate(self) {}
}

impl ValidateInput for u32 {
    fn validate(self) {}
}

impl ValidateInput for u64 {
    fn validate(self) {}
}

impl ValidateInput for i8 {
    fn validate(self) {}
}
impl ValidateInput for i16 {
    fn validate(self) {}
}
impl ValidateInput for i32 {
    fn validate(self) {}
}

impl ValidateInput for i64 {
    fn validate(self) {}
}

impl ValidateInput for Field {
    fn validate(self) {}
}

impl ValidateInput for bool {
    fn validate(self) {}
}

impl ValidateInput for U128 {
    fn validate(self) {}
}

impl<let N: u32> ValidateInput for str<N> {
    fn validate(self) {}
}

impl<T, let N: u32> ValidateInput for [T; N]
where
    T: ValidateInput,
{
    fn validate(mut self) {
        for i in 0..N {
            self[i].validate();
        }
    }
}

impl<T, let MaxLen: u32> ValidateInput for BoundedVec<T, MaxLen>
where
    T: ValidateInput,
{
    fn validate(mut self) {
        for i in 0..MaxLen {
            if i < self.len() {
                self.get_unchecked(i).validate()
            }
        }
    }
}
