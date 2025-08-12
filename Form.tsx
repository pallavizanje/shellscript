import { useState } from "react";
import { Helmet } from "react-helmet";
import SearchBox from "../path/to/SearchBox";
import UpdateForm from "../path/to/UpdateForm";
import type { PageProps, RecordItem } from "../path/to/page.types";

export default function UpdateMatter({ title }: PageProps) {
  const [selectedRecord, setSelectedRecord] = useState<RecordItem | null>(null);
  const [submitStatus, setSubmitStatus] = useState<"success" | "error" | null>(null);

  const handleSubmitComplete = (status: "success" | "error") => {
    setSubmitStatus(status);
    setSelectedRecord(null); // hide form after submit
  };

  return (
    <main className="h-full w-full">
      <Helmet>
        <title>{title}</title>
      </Helmet>

      <section className="p-6">
        <div className="min-w-8 flex-1">
          <h3 className="text-center text-gray-900 sm:truncate sm:text-2xl">
            Update Matter
          </h3>

          <div className="pb-2 pt-2">
            <div className="p-4">
              <SearchBox
                onSelect={(record: RecordItem): void => {
                  setSelectedRecord(record); // ✅ Only set when user picks from dropdown
                  setSubmitStatus(null); // reset status
                }}
              />
            </div>
          </div>

          {/* ✅ Status messages */}
          {submitStatus === "success" && (
            <p className="text-green-600 p-4">✅ Submitted successfully!</p>
          )}
          {submitStatus === "error" && (
            <p className="text-red-600 p-4">❌ Something went wrong.</p>
          )}

          {/* ✅ Show UpdateForm only after selection */}
          {selectedRecord && (
            <div className="h-[calc(100vh-330px)] overflow-hidden">
              <UpdateForm
                selectedRecord={selectedRecord}
                onSubmitComplete={handleSubmitComplete}
              />
            </div>
          )}
        </div>
      </section>
    </main>
  );
}

// UpdateForm.tsx
import React, { useEffect, useMemo } from "react";
import { Formik, Form, Field } from "formik";
import * as Yup from "yup";
import type { RecordItem } from "../path/to/page.types";

interface Props {
  selectedRecord: RecordItem;
  onSubmitComplete?: (status: "success" | "error") => void;
}

const validationSchema = Yup.object({
  name: Yup.string().required("Name is required"),
  // add other fields...
});

export default function UpdateForm({ selectedRecord, onSubmitComplete }: Props) {
  // map selectedRecord (which may be partial) into safe initialValues
  const initialValues = useMemo(() => ({
    name: selectedRecord?.name ?? "",
    description: selectedRecord?.description ?? "",
    // add other fields with defaults
  }), [selectedRecord]);

  return (
    <Formik
      initialValues={initialValues}
      enableReinitialize={true}    // <-- important
      validateOnMount={true}       // validates immediately when mounted/initialValues change
      validationSchema={validationSchema}
      onSubmit={async (values, { resetForm }) => {
        try {
          // submit logic...
          await apiCallToSubmit(values);
          onSubmitComplete?.("success");
          // hide form handled by parent (per your existing flow)
        } catch (err) {
          onSubmitComplete?.("error");
        }
      }}
    >
      {({ isSubmitting, resetForm, validateForm, setTouched, errors }) => {
        // Run whenever selectedRecord (hence initialValues) changes
        useEffect(() => {
          // reset the form to new values
          resetForm({ values: initialValues });

          // validate and mark only the fields that currently have errors as touched
          (async () => {
            const errs = await validateForm();
            if (Object.keys(errs).length) {
              setTouched(Object.fromEntries(
                Object.keys(errs).map(key => [key, true])
              ), true);
            }
          })();
        // eslint-disable-next-line react-hooks/exhaustive-deps
        }, [initialValues]); // depends on the computed initialValues

        return (
          <Form>
            <div>
              <label>Name</label>
              <Field name="name" />
              {/* show error message component */}
            </div>

            <div>
              <label>Description</label>
              <Field name="description" />
            </div>

            <button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Submitting..." : "Submit"}
            </button>
          </Form>
        );
      }}
    </Formik>
  );
}



import React, { useEffect, useMemo } from "react";
import { useFormik } from "formik";
import * as Yup from "yup";
import type { RecordItem } from "../path/to/page.types";

interface Props {
  selectedRecord: RecordItem;
  onSubmitComplete?: (status: "success" | "error") => void;
}

const validationSchema = Yup.object({
  name: Yup.string().required("Name is required"),
  description: Yup.string().required("Description is required"),
});

export default function UpdateForm({ selectedRecord, onSubmitComplete }: Props) {
  const initialValues = useMemo(
    () => ({
      name: selectedRecord?.name ?? "",
      description: selectedRecord?.description ?? "",
    }),
    [selectedRecord]
  );

  const formik = useFormik({
    initialValues,
    enableReinitialize: true,
    validationSchema,
    validateOnMount: true,
    onSubmit: async (values) => {
      try {
        // Simulate API call
        await new Promise((res) => setTimeout(res, 500));
        onSubmitComplete?.("success");
      } catch {
        onSubmitComplete?.("error");
      }
    },
  });

  // ✅ Now we can use useEffect at top level
  useEffect(() => {
    formik.resetForm({ values: initialValues });
    formik.validateForm().then((errors) => {
      if (Object.keys(errors).length) {
        formik.setTouched(
          Object.fromEntries(Object.keys(errors).map((key) => [key, true])),
          true
        );
      }
    });
  }, [initialValues]);

  return (
    <form onSubmit={formik.handleSubmit}>
      <div>
        <label>Name</label>
        <input
          name="name"
          value={formik.values.name}
          onChange={formik.handleChange}
        />
        {formik.touched.name && formik.errors.name && (
          <div className="text-red-500">{formik.errors.name}</div>
        )}
      </div>

      <div>
        <label>Description</label>
        <input
          name="description"
          value={formik.values.description}
          onChange={formik.handleChange}
        />
        {formik.touched.description && formik.errors.description && (
          <div className="text-red-500">{formik.errors.description}</div>
        )}
      </div>

      <button type="submit" disabled={formik.isSubmitting}>
        {formik.isSubmitting ? "Submitting..." : "Submit"}
      </button>
    </form>
  );
  }
