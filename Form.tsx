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
