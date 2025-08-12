import React, { useState } from "react";
import { Formik, Form, Field } from "formik";
import { Button, Modal } from "antd";
import * as Yup from "yup";

interface UpdateFormProps {
  selectedRecord: Record<string, any>;
  onReset: () => void;
}

const validationSchema = Yup.object({
  name: Yup.string().required("Name is required"),
});

export default function UpdateForm({ selectedRecord, onReset }: UpdateFormProps) {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [pendingSubmit, setPendingSubmit] = useState<(() => void) | null>(null);

  return (
    <Formik
      enableReinitialize
      initialValues={{
        name: selectedRecord?.name || "",
        description: selectedRecord?.description || "",
      }}
      validationSchema={validationSchema}
      onSubmit={(values, actions) => {
        console.log("Submitting form with:", values);
        actions.setSubmitting(false);
      }}
    >
      {({ resetForm, submitForm, isSubmitting }) => (
        <Form className="p-4 border rounded">
          <div className="mb-4">
            <label>Name</label>
            <Field name="name" className="border p-2 w-full" />
          </div>
          <div className="mb-4">
            <label>Description</label>
            <Field name="description" className="border p-2 w-full" />
          </div>

          <div className="flex gap-2">
            <Button
              type="primary"
              onClick={() => {
                setPendingSubmit(() => submitForm);
                setIsModalVisible(true);
              }}
              loading={isSubmitting}
            >
              Submit
            </Button>

            <Button
              type="default"
              onClick={() => {
                resetForm();
                onReset();
              }}
            >
              Reset
            </Button>
          </div>

          {/* Terms & Conditions Modal */}
          <Modal
            title="Terms & Conditions"
            open={isModalVisible}
            onOk={() => {
              if (pendingSubmit) pendingSubmit();
              setIsModalVisible(false);
            }}
            onCancel={() => {
              setIsModalVisible(false);
            }}
            okText="Accept"
            cancelText="Reject"
          >
            <p>
              Please accept our Terms and Conditions before submitting the form.
            </p>
          </Modal>
        </Form>
      )}
    </Formik>
  );
}
